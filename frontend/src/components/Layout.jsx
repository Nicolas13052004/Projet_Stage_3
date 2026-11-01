import { Outlet } from 'react-router-dom';
import { useState } from 'react';
import { Layout as AntLayout } from 'antd';
import Sidebar from './Sidebar';
import useInactivityLogout from '../hooks/useInactivityLogout';

const { Content } = AntLayout;

export default function Layout() {
  useInactivityLogout();
  const [collapsed, setCollapsed] = useState(false);

  return (
    <AntLayout style={{ minHeight: '100vh', background: '#f3f6f8' }}>
      <Sidebar collapsed={collapsed} toggleCollapsed={() => setCollapsed(!collapsed)} />
      
      <AntLayout style={{ 
        marginLeft: collapsed ? 120 : 280, 
        transition: 'margin-left 0.3s cubic-bezier(0.25, 0.8, 0.25, 1)',
        background: 'transparent'
      }}>
        <Content style={{ padding: '24px' }}>
          <Outlet />
        </Content>
      </AntLayout>
    </AntLayout>
  );
}