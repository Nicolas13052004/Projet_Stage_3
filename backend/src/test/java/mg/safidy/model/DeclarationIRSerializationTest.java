package mg.safidy.model;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class DeclarationIRSerializationTest {

    @Test
    void exposeIdContribuableSansExposerLEntiteComplete() throws Exception {
        Contribuable c = new Contribuable();
        c.setIdContribuable(42L);
        c.setRaisonSociale("Test SARL");
        c.setNif("NIF-42");

        DeclarationIR d = new DeclarationIR();
        d.setIdDeclaration(7L);
        d.setContribuable(c);

        String json = new ObjectMapper().writeValueAsString(d);

        assertTrue(json.contains("\"idContribuable\":42"));
        assertFalse(json.contains("\"contribuable\""));
    }
}
