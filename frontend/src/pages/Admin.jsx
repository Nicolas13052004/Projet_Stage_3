import { useEffect, useState } from 'react';
import {
  Alert,
  Row,
  Col,
  Statistic,
  Table,
  Tag,
  Button,
  Modal,
  Form,
  Input,
  InputNumber,
  Select,
  Space,
  Typography,
} from 'antd';
import {
  TeamOutlined,
  CheckCircleOutlined,
  StopOutlined,
  SettingOutlined,
  UserAddOutlined,
  EditOutlined, // Nouvelle icône pour modifier
} from '@ant-design/icons';
import { useAuth } from '../context/AuthContext';
import { useToast } from '../context/ToastContext';
import * as adminService from '../services/adminService';
import { LoadingBlock } from '../components/Spinner';

const { Text } = Typography;

const ROLES = ['AGENT', 'RESPONSABLE', 'ADMIN'];

const couleurStatut = (statut) => {
  if (statut === 'ACTIF') return 'green';
  if (statut === 'BLOQUE') return 'red';
  return 'default';
};

export default function Admin() {
  const { agent } = useAuth();
  const toast = useToast();

  const [agents, setAgents] = useState([]);
  const [centres, setCentres] = useState([]);
  const [parametres, setParametres] = useState([]);
  const [edits, setEdits] = useState({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  
  // États pour les modales
  const [ouvertCreation, setOuvertCreation] = useState(false);
  const [agentEnEdition, setAgentEnEdition] = useState(null); // Remplace resetCible
  
  const [formCreer] = Form.useForm();
  const [formEditer] = Form.useForm();

  const charger = async () => {
    try {
      const [a, c, p] = await Promise.all([
        adminService.listerAgents(),
        adminService.listerCentres(),
        adminService.listerParametres(),
      ]);
      setAgents(a);
      setCentres(c);
      setParametres(p);
    } catch (e) {
      setError(e.response?.data?.message || 'Erreur de chargement');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (agent?.role === 'ADMIN') {
      charger();
    }
  }, [agent]);

  if (agent?.role !== 'ADMIN') {
    return (
      <div className="page-container">
        <Alert type="error" showIcon message="Acces reserve aux administrateurs." className="glass-card" />
      </div>
    );
  }

  if (loading) return <LoadingBlock message="Chargement de l administration..." />;

  const agentsActifs = agents.filter((a) => a.statut === 'ACTIF').length;
  const agentsBloques = agents.filter((a) => a.statut === 'BLOQUE').length;

  const handleCreer = async (values) => {
    try {
      await adminService.creerAgent({
        ...values,
        idCentre: values.idCentre != null && values.idCentre !== ''
          ? Number(values.idCentre)
          : centres[0]?.idCentre,
      });
      toast.success('Agent cree');
      formCreer.resetFields();
      setOuvertCreation(false);
      charger();
    } catch (e2) {
      toast.error(e2.response?.data?.message || 'Erreur');
    }
  };

  const handleStatut = async (a) => {
    const cible = a.statut === 'ACTIF' ? 'BLOQUE' : 'ACTIF';
    try {
      await adminService.changerStatutAgent(a.idAgent, cible);
      toast.success('Statut mis a jour');
      charger();
    } catch (e) {
      toast.error(e.response?.data?.message || 'Erreur');
    }
  };

  // Nouvelle fonction pour ouvrir la modale d'édition
  const ouvrirEdition = (agentCible) => {
    setAgentEnEdition(agentCible);
    formEditer.setFieldsValue({
      email: agentCible.email,
      motDePasse: '', // Vide par défaut
    });
  };

  // Nouvelle fonction pour soumettre l'édition
  const handleEditer = async (values) => {
    if (!agentEnEdition) return;
    try {
      await adminService.modifierAgent(agentEnEdition.idAgent, values);
      toast.success('Informations mises à jour');
      setAgentEnEdition(null);
      formEditer.resetFields();
      charger();
    } catch (e) {
      toast.error(e.response?.data?.message || 'Erreur lors de la modification');
    }
  };

  const handleSauverParam = async (p) => {
    const valeur = edits[p.idParam];
    if (valeur == null || valeur === '') return;
    try {
      await adminService.modifierParametre(p.idParam, Number(valeur));
      toast.success('Parametre mis a jour');
      setEdits((prev) => ({ ...prev, [p.idParam]: undefined }));
      charger();
    } catch (e) {
      toast.error(e.response?.data?.message || 'Erreur');
    }
  };

  const colonnesAgents = [
    {
      title: 'Matricule',
      dataIndex: 'matricule',
      key: 'matricule',
      render: (v) => <Text strong>{v}</Text>,
    },
    {
      title: 'Nom',
      key: 'nom',
      render: (_, a) => `${a.prenom} ${a.nom}`,
    },
    { title: 'Email', dataIndex: 'email', key: 'email' },
    {
      title: 'Role',
      dataIndex: 'role',
      key: 'role',
      render: (v) => <Tag color="geekblue">{v}</Tag>,
    },
    {
      title: 'Statut',
      dataIndex: 'statut',
      key: 'statut',
      render: (v) => <Tag color={couleurStatut(v)}>{v}</Tag>,
    },
    {
      title: 'Centre',
      key: 'centre',
      render: (_, a) => a.centre?.nom || '-',
    },
    {
      title: 'Derniere connexion',
      key: 'derniereConnexion',
      render: (_, a) =>
        a.derniereConnexion
          ? a.derniereConnexion.replace('T', ' ').substring(0, 16)
          : '-',
    },
    {
      title: 'Actions',
      key: 'actions',
      render: (_, a) => (
        <Space size={4}>
          <Button type="link" size="small" icon={<StopOutlined />} onClick={() => handleStatut(a)}>
            {a.statut === 'ACTIF' ? 'Bloquer' : 'Activer'}
          </Button>
          {/* BOUTON MODIFIÉ ICI */}
          <Button type="link" size="small" icon={<EditOutlined />} onClick={() => ouvrirEdition(a)}>
            Modifier
          </Button>
        </Space>
      ),
    },
  ];

  const colonnesParametres = [
    { title: 'Code', dataIndex: 'code', key: 'code', render: (v) => <Text strong>{v}</Text> },
    { title: 'Description', dataIndex: 'description', key: 'description' },
    {
      title: 'Valeur',
      key: 'valeur',
      render: (_, p) => (
        <InputNumber
          style={{ width: 160 }}
          value={edits[p.idParam] ?? p.valeur}
          onChange={(v) => setEdits((prev) => ({ ...prev, [p.idParam]: v }))}
        />
      ),
    },
    {
      title: '',
      key: 'action',
      width: 120,
      render: (_, p) => (
        <Button
          type="link"
          size="small"
          disabled={edits[p.idParam] == null}
          onClick={() => handleSauverParam(p)}
        >
          Enregistrer
        </Button>
      ),
    },
  ];

  return (
    <div className="page-container">
      {/* EN-TÊTE */}
      <div className="page-header-card glass-card">
        <div>
          <h1 className="page-title">Administration</h1>
          <p className="page-subtitle">Comptes agents et parametres fiscaux</p>
        </div>
      </div>

      {error && <Alert type="error" showIcon message={error} className="glass-card" />}

      {/* STATISTIQUES */}
      <Row gutter={[16, 16]}>
        <Col xs={12} md={6}>
          <div className="glass-card">
            <Statistic title="Agents" value={agents.length} prefix={<TeamOutlined style={{ color: '#0E7A55' }} />} />
          </div>
        </Col>
        <Col xs={12} md={6}>
          <div className="glass-card">
            <Statistic title="Agents actifs" value={agentsActifs} prefix={<CheckCircleOutlined style={{ color: '#16A34A' }} />} />
          </div>
        </Col>
        <Col xs={12} md={6}>
          <div className="glass-card">
            <Statistic title="Agents bloques" value={agentsBloques} prefix={<StopOutlined style={{ color: '#DC2626' }} />} />
          </div>
        </Col>
        <Col xs={12} md={6}>
          <div className="glass-card">
            <Statistic title="Parametres fiscaux" value={parametres.length} prefix={<SettingOutlined style={{ color: '#0369A1' }} />} />
          </div>
        </Col>
      </Row>

      {/* TABLEAU AGENTS */}
      <div className="glass-card">
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16 }}>
          <h3 style={{ margin: 0, fontSize: 16, fontWeight: 600, color: '#0a2c22' }}>
            Agents ({agents.length})
          </h3>
          <Button type="primary" icon={<UserAddOutlined />} onClick={() => setOuvertCreation(true)}>
            Nouvel agent
          </Button>
        </div>
        <Table
          rowKey="idAgent"
          size="small"
          columns={colonnesAgents}
          dataSource={agents}
          scroll={{ x: 1000 }}
          pagination={false}
        />
      </div>

      {/* TABLEAU PARAMETRES */}
      <div className="glass-card">
        <h3 style={{ margin: '0 0 16px 0', fontSize: 16, fontWeight: 600, color: '#0a2c22' }}>
          Parametres fiscaux ({parametres.length})
        </h3>
        <Table
          rowKey="idParam"
          size="small"
          columns={colonnesParametres}
          dataSource={parametres}
          pagination={false}
        />
      </div>

      {/* MODAL CREATION */}
      <Modal
        open={ouvertCreation}
        title="Nouvel agent"
        onCancel={() => setOuvertCreation(false)}
        footer={null}
        destroyOnHidden
        centered
        width={520}
      >
        <Form
          form={formCreer}
          layout="vertical"
          onFinish={handleCreer}
          initialValues={{ role: 'AGENT', idCentre: centres[0]?.idCentre }}
        >
          <Row gutter={12}>
            <Col xs={24} md={12}>
              <Form.Item name="matricule" label="Matricule" rules={[{ required: true }]}>
                <Input placeholder="Matricule" />
              </Form.Item>
            </Col>
            <Col xs={24} md={12}>
              <Form.Item name="nom" label="Nom" rules={[{ required: true }]}>
                <Input placeholder="Nom" />
              </Form.Item>
            </Col>
            <Col xs={24} md={12}>
              <Form.Item name="prenom" label="Prenom" rules={[{ required: true }]}>
                <Input placeholder="Prenom" />
              </Form.Item>
            </Col>
            <Col xs={24} md={12}>
              <Form.Item name="email" label="Email" rules={[{ required: true, type: 'email' }]}>
                <Input placeholder="Email" />
              </Form.Item>
            </Col>
            <Col xs={24} md={12}>
              <Form.Item name="role" label="Role">
                <Select options={ROLES.map((r) => ({ value: r, label: r }))} />
              </Form.Item>
            </Col>
            {centres.length > 1 && (
              <Col xs={24} md={12}>
                <Form.Item name="idCentre" label="Centre">
                  <Select options={centres.map((c) => ({ value: c.idCentre, label: c.nom }))} />
                </Form.Item>
              </Col>
            )}
            <Col span={24}>
              <Form.Item name="motDePasse" label="Mot de passe" rules={[{ required: true, min: 8 }]}>
                <Input.Password placeholder="Mot de passe" />
              </Form.Item>
            </Col>
          </Row>
          <Button type="primary" htmlType="submit" block icon={<UserAddOutlined />}>
            Creer l agent
          </Button>
        </Form>
      </Modal>

      {/* MODAL D'ÉDITION (Remplace l'ancienne modale de reset mdp) */}
      <Modal
        open={!!agentEnEdition}
        title={
          agentEnEdition
            ? `Modifier les informations - ${agentEnEdition.prenom} ${agentEnEdition.nom}`
            : ''
        }
        onCancel={() => setAgentEnEdition(null)}
        footer={null}
        destroyOnHidden
        centered
        width={440}
      >
        <Form form={formEditer} layout="vertical" onFinish={handleEditer}>
          <Form.Item
            name="email"
            label="Adresse e-mail"
            rules={[
              { required: true, message: 'L e-mail est obligatoire.' },
              { type: 'email', message: 'Adresse invalide.' },
            ]}
          >
            <Input placeholder="Nouvel e-mail" />
          </Form.Item>
          <Form.Item
            name="motDePasse"
            label="Nouveau mot de passe (optionnel)"
            extra="Laissez vide pour conserver le mot de passe actuel."
            rules={[
              { min: 8, message: '8 caracteres minimum' },
            ]}
          >
            <Input.Password placeholder="Nouveau mot de passe" />
          </Form.Item>
          <Button type="primary" htmlType="submit" block icon={<EditOutlined />}>
            Enregistrer les modifications
          </Button>
        </Form>
      </Modal>
    </div>
  );
}