package mg.safidy.service;

import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class EmailService {

    private final JavaMailSender mailSender;

    public EmailService(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    public void envoyerEmailAvertissement(String destinataire) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setTo(destinataire);
        message.setSubject("Avertissement : Tentatives de connexion échouées");
        message.setText("Attention : vous avez échoué 3 tentatives de connexion.\n" +
                "Il vous reste 2 tentatives avant le blocage de votre compte.");
        mailSender.send(message);
    }

    public void envoyerEmailBlocage(String destinataire) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setTo(destinataire);
        message.setSubject("Alerte : Votre compte est bloqué");
        message.setText("Votre compte est bloqué suite à 5 tentatives de connexion échouées.\n" +
                "Veuillez contacter l'administrateur.");
        mailSender.send(message);
    }

    public void envoyerEmailAdminBlocage(String emailAdmin, String nomUtilisateur, String emailUtilisateur) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setTo(emailAdmin);
        message.setSubject("ACTION REQUISE : Compte agent bloqué");
        message.setText("Le compte de " + nomUtilisateur + " (" + emailUtilisateur + ") est bloqué après 5 tentatives échouées.\n" +
                "Merci de le renvoyer au bureau du chef pour résoudre le problème.");
        mailSender.send(message);
    }

    public void envoyerEmailDeblocage(String destinataire) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setTo(destinataire);
        message.setSubject("Votre compte a été débloqué");
        message.setText("Votre compte a été débloqué.\n" +
                "Veuillez vous rendre au bureau pour récupérer votre nouveau mot de passe.");
        mailSender.send(message);
    }
}
