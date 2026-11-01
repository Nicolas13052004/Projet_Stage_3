package mg.safidy.controller;

import mg.safidy.model.Agent;
import mg.safidy.service.AgentService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize; // IMPORTANT
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/api/admin")
@PreAuthorize("hasRole('ADMIN')") // Réservé uniquement aux Admins
public class AdminController {

    private final AgentService agentService;

    public AdminController(AgentService agentService) {
        this.agentService = agentService;
    }

    // ... (autres méthodes existantes : lister, creer, parametres, etc.) ...

    @PutMapping("/agents/{id}")
    public ResponseEntity<?> modifierAgent(@PathVariable Long id, @RequestBody Map<String, String> payload) {
        try {
            String nouvelEmail = payload.get("email");
            String nouveauMotDePasse = payload.get("motDePasse");

            if (nouvelEmail == null || nouvelEmail.isBlank()) {
                return ResponseEntity.badRequest().body(Map.of("message", "L'email est obligatoire."));
            }

            // On récupère l'agent existant
            Agent agent = agentService.trouverParId(id);

            // On met à jour les champs
            agent.setEmail(nouvelEmail);
            
            // Si un nouveau mot de passe est fourni, on le met à jour (avec hash)
            if (nouveauMotDePasse != null && !nouveauMotDePasse.isBlank()) {
                agentService.reinitialiserMotDePasse(id, nouveauMotDePasse);
            } else {
                // Si pas de nouveau mot de passe, on met juste à jour l'agent
                agentService.modifier(id, agent); 
            }

            return ResponseEntity.ok(Map.of("message", "Agent modifié avec succès."));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }
}