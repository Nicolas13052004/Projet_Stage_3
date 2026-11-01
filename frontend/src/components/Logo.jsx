import { useState } from 'react';

/**
 * Logo de l'application.
 * Charge l'image IR_logo.png depuis le dossier src et bascule sur un
 * libellé de repli si l'image n'est pas trouvée.
 */
export default function Logo({
  size = 32,
  repli = 'IR',
  style = {},
  fondRepli = '#0E7A55', // Vert du logo
  couleurRepli = '#fff',
}) {
  const [ko, setKo] = useState(false);

  if (ko) {
    return (
      <div
        style={{
          width: size,
          height: size,
          borderRadius: Math.max(6, Math.round(size * 0.2)),
          background: fondRepli,
          color: couleurRepli,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontWeight: 700,
          fontSize: Math.max(11, Math.round(size * 0.38)),
          flexShrink: 0,
          ...style,
        }}
      >
        {repli}
      </div>
    );
  }

  return (
    <img
      // On importe l'image depuis le dossier src
      src={new URL('../IR_logo.png', import.meta.url).href}
      alt="Logo Ministère - DGI"
      onError={() => setKo(true)}
      style={{
        width: size,
        height: 'auto', // Laisse la hauteur s'adapter pour ne pas écraser le logo ovale
        maxHeight: size, // Limite la hauteur à la taille demandée
        objectFit: 'contain',
        borderRadius: Math.max(6, Math.round(size * 0.2)),
        // On enlève le fond blanc forcé pour que le logo s'intègre mieux
        background: 'transparent', 
        flexShrink: 0,
        ...style,
      }}
    />
  );
}