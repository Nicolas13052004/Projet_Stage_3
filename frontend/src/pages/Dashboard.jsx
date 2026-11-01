import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Row,
  Col,
  Statistic,
  Progress,
  Table,
  Tag,
  Button,
  Alert,
  Typography,
} from 'antd';
import {
  TeamOutlined,
  FileTextOutlined,
  CreditCardOutlined,
  CalendarOutlined,
  WarningOutlined,
  ClockCircleOutlined,
} from '@ant-design/icons';
import { useAuth } from '../context/AuthContext';
import * as statService from '../services/statistiqueService';
import * as impayeService from '../services/impayeService';
import { LoadingBlock } from '../components/Spinner';
import BarChartCard from '../components/charts/BarChartCard';
import PieChartCard from '../components/charts/PieChartCard';
import { formatAr } from '../utils/format';

const { Text } = Typography;

export default function Dashboard() {
  const { agent } = useAuth();
  const navigate = useNavigate();
  const [stats, setStats] = useState(null);
  const [parAnnee, setParAnnee] = useState([]);
  const [parStatut, setParStatut] = useState([]);
  const [alertes, setAlertes] = useState(null);
  const [impayes, setImpayes] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    Promise.all([
      statService.resume(),
      statService.parAnnee(),
      statService.parStatut(),
      statService.alertes().catch(() => null),
      impayeService.lister(new Date().getFullYear()).catch(() => []),
    ])
      .then(([r, a, s, al, im]) => {
        setStats(r);
        setParAnnee(a);
        setParStatut(s);
        setAlertes(al);
        setImpayes(im);
      })
      .catch((e) => setError(e.response?.data?.message || 'Erreur de chargement'))
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <LoadingBlock message="Chargement du tableau de bord..." />;

  const annee = new Date().getFullYear();
  const heure = new Date().getHours();
  const salutation = heure < 12 ? 'Bonjour' : heure < 18 ? 'Bon après-midi' : 'Bonsoir';

  const impayesTries = [...(impayes || [])]
    .sort((a, b) => (b.resteAPayer || 0) - (a.resteAPayer || 0))
    .slice(0, 5);

  const colonnesImpayes = [
    {
      title: 'Contribuable',
      key: 'contribuable',
      render: (_, r) => (
        <div>
          <Text strong>{r.raisonSociale}</Text>
          <br />
          <Text type="secondary" style={{ fontSize: 12 }}>{r.nif}</Text>
        </div>
      ),
    },
    {
      title: 'IR dû',
      dataIndex: 'irDu',
      key: 'irDu',
      align: 'right',
      render: (v) => formatAr(v),
    },
    {
      title: 'Reste à payer',
      dataIndex: 'resteAPayer',
      key: 'reste',
      align: 'right',
      render: (v) => (
        <Text type="danger" strong>
          {formatAr(v)}
        </Text>
      ),
    },
    {
      title: '',
      key: 'action',
      width: 90,
      render: () => (
        <Button type="link" size="small" onClick={() => navigate('/recouvrement')}>
          Relancer
        </Button>
      ),
    },
  ];

  const colonnesEcheances = [
    { title: 'Contribuable', dataIndex: 'raisonSociale', key: 'rs' },
    {
      title: 'Année / n',
      key: 'ref',
      render: (_, a) => `${a.annee} n°${a.numero}`,
    },
    { title: 'Échéance', dataIndex: 'dateEcheance', key: 'echeance' },
    {
      title: 'Montant',
      dataIndex: 'montant',
      key: 'montant',
      align: 'right',
      render: (v) => formatAr(v),
    },
    {
      title: 'Dans',
      dataIndex: 'joursRestants',
      key: 'jours',
      render: (j) => (
        <Tag color={j <= 7 ? 'red' : 'orange'}>{j} j</Tag>
      ),
    },
  ];

  return (
    <div className="page-container">
      {/* En-tête */}
      <div className="page-header-card glass-card">
        <div>
          <h1 className="page-title">Tableau de bord</h1>
          <p className="page-subtitle">
            {salutation} {agent?.prenom} {agent?.nom} — {agent?.role}
          </p>
        </div>
      </div>

      {error && <Alert type="error" showIcon message={error} className="glass-card" />}

      {stats && (
        <>
          {/* Ligne 1 : Stats globales */}
          <Row gutter={[16, 16]}>
            <Col xs={12} md={6}>
              <div className="glass-card">
                <Statistic
                  title="Contribuables"
                  value={stats.contribuables}
                  prefix={<TeamOutlined style={{ color: '#0E7A55' }} />}
                />
              </div>
            </Col>
            <Col xs={12} md={6}>
              <div className="glass-card">
                <Statistic
                  title="Déclarations IR"
                  value={stats.declarations}
                  prefix={<FileTextOutlined style={{ color: '#0369A1' }} />}
                />
              </div>
            </Col>
            <Col xs={12} md={6}>
              <div className="glass-card">
                <Statistic
                  title="Paiements"
                  value={stats.paiements}
                  prefix={<CreditCardOutlined style={{ color: '#16A34A' }} />}
                />
              </div>
            </Col>
            <Col xs={12} md={6}>
              <div className="glass-card">
                <Statistic
                  title="Acomptes"
                  value={stats.acomptes}
                  prefix={<CalendarOutlined style={{ color: '#EA580C' }} />}
                />
              </div>
            </Col>
          </Row>

          {/* Ligne 2 : Montants */}
          <Row gutter={[16, 16]}>
            <Col xs={24} md={8} lg={5}>
              <div className="glass-card">
                <Statistic title={`IR total dû (${annee})`} value={stats.irTotal} precision={0} suffix="Ar" valueStyle={{ fontSize: 18 }} />
              </div>
            </Col>
            <Col xs={24} md={8} lg={5}>
              <div className="glass-card">
                <Statistic
                  title="Total encaissé"
                  value={stats.encaisse}
                  precision={0}
                  suffix="Ar"
                  valueStyle={{ color: '#16A34A', fontSize: 18 }}
                />
              </div>
            </Col>
            <Col xs={24} md={8} lg={5}>
              <div className="glass-card">
                <Statistic
                  title="Reste à payer"
                  value={stats.soldeAPayer}
                  precision={0}
                  suffix="Ar"
                  valueStyle={{ color: '#EA580C', fontSize: 18 }}
                />
              </div>
            </Col>
            <Col xs={12} md={6} lg={5}>
              <div className="glass-card">
                <Statistic
                  title="En retard"
                  value={
                    alertes ? alertes.nbContribuablesEnRetard : stats.nbEnRetard || 0
                  }
                  prefix={<WarningOutlined style={{ color: '#DC2626' }} />}
                  valueStyle={{ color: '#DC2626', fontSize: 18 }}
                />
              </div>
            </Col>
            <Col xs={12} md={6} lg={4}>
              <div className="glass-card">
                <div style={{ fontSize: 14, color: 'rgba(0,0,0,0.45)', marginBottom: 4 }}>Taux de recouvrement</div>
                <Text strong style={{ fontSize: 18 }}>
                  {stats.tauxRecouvrement} %
                </Text>
                <Progress
                  percent={Math.min(Number(stats.tauxRecouvrement) || 0, 100)}
                  showInfo={false}
                  strokeColor="#0E7A55"
                  size="small"
                />
              </div>
            </Col>
          </Row>

          {/* Ligne 3 : Graphiques */}
          <Row gutter={[16, 16]}>
            <Col xs={24} lg={14}>
              <div className="glass-card" style={{ height: '100%' }}>
                <BarChartCard
                  titre="IR dû par année"
                  data={parAnnee}
                  cleX="annee"
                  series={[
                    { dataKey: 'irDu', name: 'IR dû', couleur: '#0E7A55' },
                    { dataKey: 'soldeAPayer', name: 'Solde à payer', couleur: '#F59E0B' },
                  ]}
                />
              </div>
            </Col>
            <Col xs={24} lg={10}>
              <div className="glass-card" style={{ height: '100%' }}>
                <PieChartCard
                  titre="Déclarations par statut"
                  data={parStatut}
                  cleNom="statut"
                  cleValeur="nombre"
                />
              </div>
            </Col>
          </Row>

          {/* Ligne 4 : Alertes et impayés */}
          {(alertes || impayes) && (
            <Row gutter={[16, 16]}>
              <Col xs={24} lg={12}>
                <div className="glass-card">
                  <h3 style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 16, fontSize: 16 }}>
                    <WarningOutlined style={{ color: '#DC2626' }} />
                    Top 5 des impayés (
                    {formatAr((impayes || []).reduce((t, i) => t + (i.resteAPayer || 0), 0))} à recouvrer)
                  </h3>
                  <Table
                    size="small"
                    rowKey="idDeclaration"
                    columns={colonnesImpayes}
                    dataSource={impayesTries}
                    pagination={false}
                    locale={{ emptyText: 'Aucun impayé' }}
                  />
                </div>
              </Col>
              <Col xs={24} lg={12}>
                {alertes && (
                <div className="glass-card">
                  <h3 style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 16, fontSize: 16 }}>
                    <ClockCircleOutlined style={{ color: '#F59E0B' }} />
                    Échéances dans les 30 jours ({alertes.acomptesAvenir.length})
                  </h3>
                  <Table
                    size="small"
                    rowKey="idAcompte"
                    columns={colonnesEcheances}
                    dataSource={alertes.acomptesAvenir}
                    pagination={false}
                    locale={{ emptyText: 'Aucune échéance imminente' }}
                  />
                </div>
                )}
              </Col>
            </Row>
          )}
        </>
      )}
    </div>
  );
}