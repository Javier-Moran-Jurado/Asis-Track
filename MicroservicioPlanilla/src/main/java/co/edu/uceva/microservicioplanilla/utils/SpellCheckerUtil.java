package co.edu.uceva.microservicioplanilla.utils;

import java.util.*;

public class SpellCheckerUtil {

    private static final Set<String> DICTIONARY = new HashSet<>(Arrays.asList(
            "después", "visita", "biblioteca", "instituto", "tecnológico", "estudios", "superiores",
            "monterrey", "impresionado", "rebosante", "placenteras", "curiosidades", "resecuenci",
            "colección", "tesoros", "documentales", "bibliográficos", "cautivadora", "riquísima",
            "inmensa", "histórica", "mágico", "temblor", "exclamación", "algunos", "autógrafos",
            "escritura", "admiración", "ilustres", "personas", "contenían", "biblioteca", "gran",
            "cuerpo", "inteligencia", "eficacia", "contribuyeron", "coleccionar", "clasificar",
            "poner", "servicio", "instituciones", "materiales", "Juan", "Decasón", "Siche",
            "planilla", "asistencia", "justificación", "estudiante", "código", "universidad"
    ));

    private SpellCheckerUtil() {}

    public static String correctText(String text) {
        if (text == null || text.isEmpty()) return text;
        String[] words = text.split("\\s+");
        List<String> corrected = new ArrayList<>();
        for (String word : words) {
            String punctuation = "";
            if (word.length() > 0 && ".,;:!?".indexOf(word.charAt(word.length() - 1)) >= 0) {
                punctuation = word.substring(word.length() - 1);
                word = word.substring(0, word.length() - 1);
            }
            String lowerWord = word.toLowerCase();
            if (DICTIONARY.contains(lowerWord)) {
                corrected.add(word + punctuation);
            } else {
                String suggestion = findClosestWord(lowerWord);
                if (suggestion != null && !suggestion.equals(lowerWord)) {
                    // Conservar mayúscula inicial si la original la tenía
                    if (Character.isUpperCase(word.charAt(0))) {
                        suggestion = Character.toUpperCase(suggestion.charAt(0)) + suggestion.substring(1);
                    }
                    corrected.add(suggestion + punctuation);
                } else {
                    corrected.add(word + punctuation);
                }
            }
        }
        return String.join(" ", corrected);
    }

    private static String findClosestWord(String word) {
        int minDistance = Integer.MAX_VALUE;
        String closest = null;
        for (String dictWord : DICTIONARY) {
            int distance = levenshteinDistance(word, dictWord);
            if (distance < minDistance) {
                minDistance = distance;
                closest = dictWord;
                if (distance == 0) break;
            }
        }
        return (minDistance <= 2) ? closest : word;
    }

    private static int levenshteinDistance(String a, String b) {
        int[][] dp = new int[a.length() + 1][b.length() + 1];
        for (int i = 0; i <= a.length(); i++) dp[i][0] = i;
        for (int j = 0; j <= b.length(); j++) dp[0][j] = j;
        for (int i = 1; i <= a.length(); i++) {
            for (int j = 1; j <= b.length(); j++) {
                int cost = (a.charAt(i - 1) == b.charAt(j - 1)) ? 0 : 1;
                dp[i][j] = Math.min(Math.min(dp[i - 1][j] + 1, dp[i][j - 1] + 1), dp[i - 1][j - 1] + cost);
            }
        }
        return dp[a.length()][b.length()];
    }
}