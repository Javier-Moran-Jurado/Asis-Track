package co.edu.uceva.microservicioseguridad.domain.service;

import co.edu.uceva.microservicioseguridad.delivery.dto.PrivateKeyDTO;
import co.edu.uceva.microservicioseguridad.delivery.dto.PublicKeyDTO;

public interface ISecurityKeyService {
    void rotarLlaves();
    PublicKeyDTO getPublicKey();
    PrivateKeyDTO getPrivateKey();
    PrivateKeyDTO getPrivateKeyById(Long id);
}
