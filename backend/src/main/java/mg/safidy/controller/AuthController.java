package mg.safidy.controller;

import mg.safidy.dto.LoginRequest;
import mg.safidy.dto.LoginResponse;
import mg.safidy.exception.BusinessException;
import mg.safidy.model.Agent;
import mg.safidy.repository.AgentRepository;
import mg.safidy.security.JwtService;
import mg.safidy.service.AgentService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AgentRepository agentRepository;
    private final AgentService agentService;
    private final JwtService jwtService;
    private final PasswordEncoder passwordEncoder;

    public AuthController(AgentRepository agentRepository, 
                          AgentService agentService, 
                          JwtService jwtService, 
                          PasswordEncoder passwordEncoder) {
        this.agentRepository = agentRepository;
        this.agentService = agentService;
        this.jwtService = jwtService;
        this.passwordEncoder = passwordEncoder;
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest req) {
        System.out.println(">>> TENTATIVE DE CONNEXION (SECURISÉE)");
        
        if (req.getEmail() == null || req.getEmail().isBlank()
                || req.getMotDePasse() == null || req.getMotDePasse().isBlank()) {
            throw new BusinessException("E-mail et mot de passe obligatoires");
        }

        Agent agent = agentRepository.findByEmail(req.getEmail())
                .orElseThrow(() -> new BusinessException("E-mail ou mot de passe incorrect"));

        if ("BLOQUE".equals(agent.getStatut())) {
            System.out.println(">>> COMPTE BLOQUE : " + agent.getEmail());
            throw new BusinessException("Compte bloqué. Contactez l'administrateur.");
        }

        if (!passwordEncoder.matches(req.getMotDePasse(), agent.getMotDePasseHash())) {
            System.out.println(">>> ECHEC : Mot de passe incorrect.");
            agentService.enregistrerEchecConnexion(agent); 
            throw new BusinessException("E-mail ou mot de passe incorrect");
        }

        System.out.println(">>> SUCCES : Connexion autorisée !");
        agentService.enregistrerConnexionReussie(agent);

        String token = jwtService.genererToken(agent);
        LoginResponse resp = new LoginResponse(
                token, agent.getIdAgent(), agent.getNom(),
                agent.getPrenom(), agent.getEmail(), agent.getRole());

        return ResponseEntity.ok(resp);
    }

    // NOUVELLE ROUTE POUR VÉRIFIER LE STATUT
    @GetMapping("/check-status")
    public ResponseEntity<?> checkStatus(@RequestParam String email) {
        Optional<Agent> agentOpt = agentRepository.findByEmail(email);
        
        Map<String, Object> response = new HashMap<>();

        if (agentOpt.isEmpty()) {
            response.put("existe", false);
            response.put("message", "Aucun compte associé à cet e-mail.");
            return ResponseEntity.ok(response);
        }

        Agent agent = agentOpt.get();
        boolean estBloque = "BLOQUE".equals(agent.getStatut());
        int tentatives = agent.getTentativesEchec() != null ? agent.getTentativesEchec() : 0;
        int restantes = 5 - tentatives;

        response.put("existe", true);
        
        if (estBloque) {
            response.put("statut", "BLOQUE");
            response.put("message", "Votre compte est bloqué. Veuillez contacter l'administrateur.");
        } else {
            response.put("statut", "ACTIF");
            response.put("tentativesRestantes", restantes > 0 ? restantes : 0);
            if (restantes <= 2) {
                response.put("message", "Attention : il ne vous reste que " + restantes + " tentative(s) avant le blocage.");
            } else {
                response.put("message", "Compte actif. Il vous reste " + restantes + " tentatives.");
            }
        }

        return ResponseEntity.ok(response);
    }
}