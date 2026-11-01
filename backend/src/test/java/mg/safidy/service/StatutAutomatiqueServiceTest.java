package mg.safidy.service;

import mg.safidy.model.DeclarationIR;
import mg.safidy.repository.AcompteRepository;
import mg.safidy.repository.DeclarationIRRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class StatutAutomatiqueServiceTest {

    @Mock
    private DeclarationIRRepository declarationRepository;
    @Mock
    private AcompteRepository acompteRepository;

    private StatutAutomatiqueService service;

    @BeforeEach
    void setUp() {
        service = new StatutAutomatiqueService(declarationRepository, acompteRepository);
        when(acompteRepository.findAll()).thenReturn(List.of());
    }

    @Test
    void brouillonResteBrouillonMemeApresLaDateLimite() {
        DeclarationIR d = declaration("BROUILLON", null);
        when(declarationRepository.findAll()).thenReturn(List.of(d));

        service.appliquerRetards();

        assertEquals("BROUILLON", d.getStatut());
        verify(declarationRepository, never()).save(any(DeclarationIR.class));
    }

    @Test
    void declarationValideeImpayeeDevientEnRetard() {
        DeclarationIR d = declaration("VALIDEE", LocalDate.now().minusMonths(1));
        when(declarationRepository.findAll()).thenReturn(List.of(d));

        service.appliquerRetards();

        assertEquals("EN_RETARD", d.getStatut());
        verify(declarationRepository).save(d);
    }

    @Test
    void ancienBrouillonEnRetardEstRestaure() {
        DeclarationIR d = declaration("EN_RETARD", null);
        when(declarationRepository.findAll()).thenReturn(List.of(d));

        service.appliquerRetards();

        assertEquals("BROUILLON", d.getStatut());
        verify(declarationRepository).save(d);
    }

    @Test
    void declarationPayeeNEstPasModifiee() {
        DeclarationIR d = declaration("PAYEE", null);
        when(declarationRepository.findAll()).thenReturn(List.of(d));

        service.appliquerRetards();

        assertEquals("PAYEE", d.getStatut());
        verify(declarationRepository, never()).save(any(DeclarationIR.class));
    }

    private DeclarationIR declaration(String statut, LocalDate dateDepot) {
        DeclarationIR d = new DeclarationIR();
        d.setStatut(statut);
        d.setDateDepot(dateDepot);
        d.setDateLimite(LocalDate.now().minusDays(1));
        return d;
    }
}
