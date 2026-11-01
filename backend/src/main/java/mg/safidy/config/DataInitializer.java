package mg.safidy.config;

import mg.safidy.model.Agent;
import mg.safidy.model.CentreFiscal;
import mg.safidy.repository.AgentRepository;
import mg.safidy.repository.CentreFiscalRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.LocalDateTime;

@Configuration
public class DataInitializer {

    @Bean
    public CommandLineRunner initDatabase(AgentRepository agentRepository, 
                                          CentreFiscalRepository centreRepository, 
                                          PasswordEncoder passwordEncoder) {
        return args -> {
            // 1. Vérifier ou créer le centre fiscal
            CentreFiscal centre;
            if (centreRepository.count() == 0) {
                centre = new CentreFiscal();
                centre.setCode("CF-ANT-01");
                centre.setNom("Centre Fiscal d'Antananarivo");
                centre = centreRepository.save(centre);
                System.out.println(">>> CENTRE FISCAL CRÉÉ");
            } else {
                centre = centreRepository.findAll().get(0);
            }

            // 2. Vérifier si l'admin existe DÉJÀ par son email OU son matricule
            if (agentRepository.findByEmail("admin@safidy.mg").isEmpty() 
                && agentRepository.findByMatricule("ADMIN001").isEmpty()) {
                
                Agent admin = new Agent();
                admin.setMatricule("ADMIN001");
                admin.setNom("Admin");
                admin.setPrenom("Super");
                admin.setEmail("admin@safidy.mg");
                admin.setMotDePasseHash(passwordEncoder.encode("admin1234"));
                admin.setRole("ADMIN");
                admin.setStatut("ACTIF");
                admin.setTentativesEchec(0);
                admin.setDateCreation(LocalDateTime.now());
                admin.setCentre(centre);
                
                agentRepository.save(admin);
                System.out.println(">>> UTILISATEUR ADMIN CRÉÉ AVEC SUCCÈS !");
            } else {
                System.out.println(">>> L'UTILISATEUR ADMIN EXISTE DÉJÀ. Initialisation ignorée.");
            }
        };
    }
}