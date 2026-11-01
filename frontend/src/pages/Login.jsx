import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Form, Input, Button, Typography, Alert, Checkbox } from 'antd';
import { LockOutlined, MailOutlined } from '@ant-design/icons';
import { useAuth } from '../context/AuthContext';
import Logo from '../components/Logo';
import api from '../services/api';

const { Title, Text } = Typography;

export default function Login() {
  const [form] = Form.useForm();
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [statutCompte, setStatutCompte] = useState(null);

  const { login, isAuth } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    if (isAuth) navigate('/dashboard', { replace: true });
  }, [isAuth, navigate]);

  const verifierStatutEmail = async () => {
    const email = form.getFieldValue('email');
    if (!email) return;
    try {
      const { data } = await api.get(`/auth/check-status?email=${email}`);
      setStatutCompte(data);
    } catch (err) {
      console.error("Erreur de vérification", err);
    }
  };

  const handleSubmit = async (values) => {
    setError('');
    setLoading(true);
    try {
      await login(values.email, values.motDePasse);
      navigate('/dashboard', { replace: true });
    } catch (err) {
      const messageErreur = err.response?.data?.message || 
        (!err.response ? 'Serveur inaccessible.' : 'Erreur de connexion.');
      if (!messageErreur.includes("Compte bloqué")) {
        setError(messageErreur);
      }
      verifierStatutEmail();
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="split-login-container">
      {/* Colonne de gauche (Bleue avec vagues) */}
      <div className="split-login-left">
        <div className="login-waves"></div>
        <div className="split-left-content">
          <div className="brand-wrapper">
            <Logo size={90} />
            <Title level={2} style={{ color: '#fff', marginTop: '16px' }}>
              Gestion IR
            </Title>
            <Text style={{ color: 'rgba(255,255,255,0.8)' }}>
              Ministère de l'Économie et des Finances
            </Text>
          </div>
          
          <div className="left-footer-text">
            <p>Bienvenue sur votre espace sécurisé.</p>
            <p>Gérez vos déclarations et vos paiements en toute simplicité.</p>
          </div>
        </div>
      </div>

      {/* Colonne de droite (Blanche avec formulaire) */}
      <div className="split-login-right">
        <div className="form-wrapper">
          <div className="form-header">
            <Title level={3}>Connexion Agent</Title>
            <Text type="secondary">Entrez vos identifiants pour accéder à votre compte</Text>
          </div>

          {error && <Alert type="error" showIcon message={error} style={{ marginBottom: 20 }} closable onClose={() => setError('')} />}

          <Form
            form={form}
            layout="vertical"
            onFinish={handleSubmit}
            size="large"
            className="modern-form"
          >
            <Form.Item
              name="email"
              label="Adresse e-mail"
              rules={[
                { required: true, message: 'E-mail requis' },
                { type: 'email', message: 'Adresse invalide' },
              ]}
            >
              <Input
                prefix={<MailOutlined style={{ color: '#0E7A55' }} />}
                placeholder="votre.email@centre.mg"
                autoComplete="username"
                disabled={loading}
                onBlur={verifierStatutEmail}
              />
            </Form.Item>

            {statutCompte && statutCompte.existe && (
              <div style={{ marginBottom: 18, marginTop: -10 }}>
                {statutCompte.statut === 'BLOQUE' ? (
                  <Alert type="error" showIcon message={statutCompte.message} />
                ) : (
                  <Alert type="info" showIcon message={statutCompte.message} />
                )}
              </div>
            )}

            <Form.Item
              name="motDePasse"
              label="Mot de passe"
              rules={[{ required: true, message: 'Mot de passe requis' }]}
            >
              <Input.Password
                prefix={<LockOutlined style={{ color: '#0E7A55' }} />}
                placeholder="Votre mot de passe"
                autoComplete="current-password"
                disabled={loading}
              />
            </Form.Item>

            <div className="form-options">
              <Checkbox disabled={loading}>Se souvenir de moi</Checkbox>
              <a href="#" onClick={(e) => e.preventDefault()} className="forgot-link">
                Mot de passe oublié ?
              </a>
            </div>

            <Button type="primary" htmlType="submit" block loading={loading} className="modern-submit-btn">
              SE CONNECTER
            </Button>
          </Form>
        </div>
      </div>
    </div>
  );
}