package co.edu.uceva.microservicioseguridad.domain.service;

import co.edu.uceva.microservicioseguridad.delivery.dto.PrivateKeyDTO;
import co.edu.uceva.microservicioseguridad.delivery.dto.PublicKeyDTO;
import co.edu.uceva.microservicioseguridad.domain.model.SecurityKey;
import co.edu.uceva.microservicioseguridad.domain.repository.ISecurityKeyRepository;
import co.uceva.edu.security.RSA.RSAEncryption;
import co.uceva.edu.security.RSA.RSAKeyPair;
import co.uceva.edu.security.RSA.RSAPublicKey;
import co.uceva.edu.security.RSA.RSAPrivateKey;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigInteger;
import java.time.LocalDateTime;

@Service
public class SecurityKeyServiceImpl implements ISecurityKeyService {

    @Autowired
    private ISecurityKeyRepository repository;

    @Value("${app.security.master-key-e}")
    private long masterE;

    @Value("${app.security.master-key-n}")
    private String masterN;

    @Value("${app.security.master-key-d}")
    private String masterD;

    @Autowired
    private StringRedisTemplate redisTemplate;

    // Ejecuta la rotación cada semana (604800000 ms) - Puedes ajustarlo en el cron si prefieres: @Scheduled(cron = "0 0 0 * * SUN")
    @Override
    @Transactional
    @Scheduled(fixedDelayString = "${app.security.rotation-delay:604800000}") 
    public void rotarLlaves() {
        
        // 1. Generar nuevo par RSA
        RSAKeyPair newKeyPair = RSAEncryption.generateKeyPair();
        
        // 2. Desactivar llave anterior (si existe)
        repository.findByActiveTrue().ifPresent(oldKey -> {
            oldKey.setActive(false);
            repository.save(oldKey);
        });
        
        // 3. Preparar nueva llave persistente
        SecurityKey newKey = new SecurityKey();
        newKey.setCreatedAt(LocalDateTime.now());
        newKey.setActive(true);
        newKey.setPublicE(newKeyPair.getPublicKey().getE());
        newKey.setPublicN(newKeyPair.getPublicKey().getN().toString());
        
        // 4. Encriptar la parte privada (d) usando la Master RSA Key
        String dString = newKeyPair.getPrivateKey().getD().toString();
        RSAPublicKey masterPublicKey = new RSAPublicKey(masterE, new BigInteger(masterN));
        String encryptedD = RSAEncryption.encrypt(masterPublicKey, dString);
        newKey.setEncryptedPrivateD(encryptedD);
        
        repository.save(newKey);
        System.out.println("Nueva llave generada y activada con ID: " + newKey.getId());

        // 5. Invalidar caché en Microservicio de Usuarios directamente en Redis
        try {
            redisTemplate.delete("securityKeys::active_private");
            redisTemplate.delete("securityKeys::active_public");
            System.out.println("Caché de llaves invalidada en Redis.");
        } catch (Exception e) {
            System.err.println("No se pudo invalidar el caché de Redis: " + e.getMessage());
        }
    }

    @Override
    public PublicKeyDTO getPublicKey() {
        SecurityKey currentKey = repository.findByActiveTrue()
            .orElseThrow(() -> new RuntimeException("No hay llaves activas"));
            
        return new PublicKeyDTO(currentKey.getId(), currentKey.getPublicN(), currentKey.getPublicE());
    }

    @Override
    public PrivateKeyDTO getPrivateKey() {
        SecurityKey currentKey = repository.findByActiveTrue()
            .orElseThrow(() -> new RuntimeException("No hay llaves activas"));
            
        RSAPrivateKey masterPrivateKey = new RSAPrivateKey(new BigInteger(masterN), new BigInteger(masterD));
        String decryptedD = RSAEncryption.decrypt(masterPrivateKey, currentKey.getEncryptedPrivateD());
        
        return new PrivateKeyDTO(currentKey.getId(), decryptedD, currentKey.getPublicN());
    }

    @Override
    public PrivateKeyDTO getPrivateKeyById(Long id) {
        SecurityKey key = repository.findById(id)
            .orElseThrow(() -> new RuntimeException("Llave no encontrada"));
            
        RSAPrivateKey masterPrivateKey = new RSAPrivateKey(new BigInteger(masterN), new BigInteger(masterD));
        String decryptedD = RSAEncryption.decrypt(masterPrivateKey, key.getEncryptedPrivateD());
        
        return new PrivateKeyDTO(key.getId(), decryptedD, key.getPublicN());
    }

    // Inicializar llave en el primer arranque si no hay ninguna
    @PostConstruct
    public void init() {
        if (repository.findByActiveTrue().isEmpty()) {
            rotarLlaves();
        }
    }
}
