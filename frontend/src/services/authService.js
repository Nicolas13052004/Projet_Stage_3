import api from './api';

export const login = async (email, motDePasse) => {
  // On envoie 'motDePasse' pour correspondre exactement à ce qu'attend le backend Java
  const { data } = await api.post('/auth/login', { email, motDePasse });
  return data;
};