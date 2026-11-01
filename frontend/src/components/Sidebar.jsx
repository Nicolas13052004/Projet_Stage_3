import { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { Avatar, Typography, Tooltip } from 'antd';
import {
  DashboardOutlined, TeamOutlined, FileTextOutlined, FallOutlined, CalendarOutlined,
  CreditCardOutlined, WarningOutlined, PauseCircleOutlined, AuditOutlined, SettingOutlined,
  LogoutOutlined, UserOutlined, MenuFoldOutlined, MenuUnfoldOutlined,
} from '@ant-design/icons';
import { useAuth } from '../context/AuthContext';
import Logo from './Logo';

const { Text } = Typography;

const MENU_ITEMS = [
  { path: '/dashboard', label: 'Tableau de bord', icon: <DashboardOutlined /> },
  { path: '/contribuables', label: 'Contribuables', icon: <TeamOutlined /> },
  { path: '/declarations', label: 'Declarations IR', icon: <FileTextOutlined /> },
  { path: '/deficits', label: 'Deficits', icon: <FallOutlined /> },
  { path: '/acomptes', label: 'Acomptes', icon: <CalendarOutlined /> },
  { path: '/paiements', label: 'Paiements', icon: <CreditCardOutlined /> },
  { path: '/penalites', label: 'Penalites', icon: <WarningOutlined /> },
  { path: '/suspensions', label: 'Arret / reprise', icon: <PauseCircleOutlined /> },
  
  // Restriction par tableau de rôles
  { path: '/audit', label: "Journal d'audit", icon: <AuditOutlined />, roles: ['RESPONSABLE', 'ADMIN'] },
  { path: '/admin', label: 'Administration', icon: <SettingOutlined />, roles: ['ADMIN'] },
];

export default function Sidebar({ collapsed, toggleCollapsed }) {
  const { agent, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  // On filtre selon le tableau de rôles
  const filteredMenu = MENU_ITEMS.filter((m) => {
    if (!m.roles) return true; // Accessible à tous
    return m.roles.includes(agent?.role); // Vérifie si le rôle est dans la liste
  });

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <div className={`glass-sidebar ${collapsed ? 'collapsed' : 'expanded'}`}>
      <div className="mac-dots">
        <span className="dot red"></span>
        <span className="dot yellow"></span>
        <span className="dot green"></span>
      </div>

      <div className="sidebar-header">
        <div className="logo-container" onClick={() => navigate('/dashboard')}>
          <Logo size={collapsed ? 32 : 40} repli="IR" />
          {!collapsed && <span className="logo-text">Gestion IR</span>}
        </div>
        {!collapsed && (
          <div className="user-profile">
            <Avatar size={40} style={{ backgroundColor: 'rgba(255,255,255,0.2)' }} icon={<UserOutlined />} />
            <div className="user-info">
              <Text strong style={{ color: '#fff', display: 'block', lineHeight: 1 }}>
                {agent?.prenom} {agent?.nom}
              </Text>
              <Text style={{ color: 'rgba(255,255,255,0.6)', fontSize: 12 }}>
                {agent?.role}
              </Text>
            </div>
          </div>
        )}
      </div>

      <div className="sidebar-menu">
        {!collapsed && <div className="menu-label">MENU</div>}
        {filteredMenu.map((item) => {
          const isActive = location.pathname.startsWith(item.path);
          return (
            <Tooltip key={item.path} title={collapsed ? item.label : ''} placement="right" color="#0a5e41">
              <div className={`menu-item ${isActive ? 'active' : ''}`} onClick={() => navigate(item.path)}>
                <span className="menu-icon">{item.icon}</span>
                {!collapsed && <span className="menu-text">{item.label}</span>}
              </div>
            </Tooltip>
          );
        })}
      </div>

      <div className="sidebar-footer">
        <div className="menu-item" onClick={handleLogout}>
          <span className="menu-icon"><LogoutOutlined /></span>
          {!collapsed && <span className="menu-text">Déconnexion</span>}
        </div>
        <div className="toggle-btn" onClick={toggleCollapsed}>
          <span className="menu-icon">{collapsed ? '→' : '←'}</span>
        </div>
      </div>
    </div>
  );
}