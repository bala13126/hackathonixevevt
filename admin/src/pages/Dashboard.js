import React, { useState, useEffect, useMemo } from 'react';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend,
  ArcElement,
  PointElement,
  LineElement,
} from 'chart.js';
import { Bar, Doughnut } from 'react-chartjs-2';
import { FiGrid, FiCheckSquare, FiMessageSquare, FiBarChart2, FiAward, FiLoader, FiActivity, FiClock, FiAlertCircle, FiTrendingUp } from 'react-icons/fi';
import './Dashboard.css';

// Register ChartJS components
ChartJS.register(
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend,
  ArcElement,
  PointElement,
  LineElement
);

const Dashboard = () => {
  const [activeTab, setActiveTab] = useState('overview');

  // Real-time Data State
  const [cases, setCases] = useState([]);
  const [tips, setTips] = useState([]);
  const [users, setUsers] = useState([]);
  const [lastUpdated, setLastUpdated] = useState(new Date());
  const [isLoading, setIsLoading] = useState(true);

  // API Configuration
  const API_BASE_URL = 'http://localhost:5000/api';

  // Fetch Data (Polling for real-time updates)
  useEffect(() => {
    const fetchData = async () => {
      try {
        const [casesRes, tipsRes, usersRes] = await Promise.all([
          fetch(`${API_BASE_URL}/cases`),
          fetch(`${API_BASE_URL}/tips`),
          fetch(`${API_BASE_URL}/users`)
        ]);

        if (casesRes.ok) setCases(await casesRes.json());
        if (tipsRes.ok) setTips(await tipsRes.json());
        if (usersRes.ok) setUsers(await usersRes.json());
        setLastUpdated(new Date());
      } catch (error) {
        console.error('Error fetching dashboard data:', error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchData();
    const interval = setInterval(fetchData, 5000); // Poll every 5 seconds
    return () => clearInterval(interval);
  }, []);

  // Actions
  const handleStatusChange = async (id, newStatus) => {
    // Optimistic UI update
    setCases(cases.map(c => c.id === id ? { ...c, status: newStatus } : c));
    
    try {
      await fetch(`${API_BASE_URL}/cases/${id}/status`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: newStatus }),
      });
    } catch (error) {
      console.error('Failed to update status:', error);
    }
  };

  const handleVerifyTip = async (id) => {
    // Optimistic UI update
    setTips(tips.map(t => t.id === id ? { ...t, verified: true } : t));
    
    try {
      await fetch(`${API_BASE_URL}/tips/${id}/verify`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
      });
    } catch (error) {
      console.error('Failed to verify tip:', error);
    }
  };

  // Analytics Data Configuration
  const urgencyData = useMemo(() => ({
    labels: ['High', 'Medium', 'Low'],
    datasets: [{
      data: [
        cases.filter(c => c.urgency === 'High').length,
        cases.filter(c => c.urgency === 'Medium').length,
        cases.filter(c => c.urgency === 'Low').length,
      ],
      backgroundColor: ['#f56565', '#ed8936', '#48bb78'],
      hoverOffset: 4,
    }]
  }), [cases]);

  const statusData = useMemo(() => ({
    labels: ['Pending', 'Active', 'Solved', 'Rejected'],
    datasets: [{
      label: 'Cases',
      data: [
        cases.filter(c => c.status === 'Pending').length,
        cases.filter(c => c.status === 'Active').length,
        cases.filter(c => c.status === 'Solved').length,
        cases.filter(c => c.status === 'Rejected').length,
      ],
      backgroundColor: '#3b82f6',
    }]
  }), [cases]);

  // Render Sections
  const renderOverview = () => (
    <div className="overview-grid">
      <div className="stat-card">
        <div>
          <h3>Total Cases</h3>
          <p>{cases.length}</p>
        </div>
        <div className="stat-icon icon-blue">
          <FiCheckSquare size={24} />
        </div>
      </div>
      <div className="stat-card">
        <div>
          <h3>Active Cases</h3>
          <p>{cases.filter(c => c.status === 'Active').length}</p>
        </div>
        <div className="stat-icon icon-green">
          <FiActivity size={24} />
        </div>
      </div>
      <div className="stat-card">
        <div>
          <h3>Pending Verification</h3>
          <p>{cases.filter(c => c.status === 'Pending').length}</p>
        </div>
        <div className="stat-icon icon-orange">
          <FiClock size={24} />
        </div>
      </div>
      <div className="stat-card">
        <div>
          <h3>Tips Received</h3>
          <p>{tips.length}</p>
        </div>
        <div className="stat-icon icon-purple">
          <FiMessageSquare size={24} />
        </div>
      </div>
    </div>
  );

  const renderCases = () => (
    <div className="table-container">
      <h2>Case Management</h2>
      <table>
        <thead>
          <tr>
            <th>Case</th>
            <th>Location</th>
            <th>Reliability</th>
            <th style={{ textAlign: 'center' }}>Urgency</th>
            <th>Status</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {cases.length === 0 ? (
            <tr><td colSpan="6" className="empty-state">No cases to display.</td></tr>
          ) : cases.map(c => (
            <tr key={c.id}>
              <td>{c.name}</td>
              <td>{c.location}</td>
              <td>
                <span className={`badge ${c.reliability < 50 ? 'red' : 'green'}`}>
                  {c.reliability}%
                </span>
              </td>
              <td style={{ textAlign: 'center' }}>
                <span className={`urgency-badge ${c.urgency.toLowerCase()}`}>{c.urgency}</span>
              </td>
              <td>
                <span className={`status-badge ${c.status.toLowerCase()}`}>{c.status}</span>
              </td>
              <td>
                {c.status === 'Pending' && (
                  <>
                    <button className="btn-approve" onClick={() => handleStatusChange(c.id, 'Active')}>Approve</button>
                    <button className="btn-reject" onClick={() => handleStatusChange(c.id, 'Rejected')}>Reject</button>
                  </>
                )}
                {c.status === 'Active' && (
                  <button className="btn-solve" onClick={() => handleStatusChange(c.id, 'Solved')}>Mark Found</button>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );

  const renderTips = () => (
    <div className="table-container">
      <h2>Tip Monitoring</h2>
      <table>
        <thead>
          <tr>
            <th>Case ID</th>
            <th>Reporter</th>
            <th>Tip Content</th>
            <th>Status</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody>
          {tips.length === 0 ? (
            <tr><td colSpan="5" className="empty-state">No tips available for review.</td></tr>
          ) : tips.map(t => (
            <tr key={t.id}>
              <td>#{t.caseId}</td>
              <td>{t.reporter}</td>
              <td>{t.content}</td>
              <td>{t.verified ? 'Verified' : 'Pending'}</td>
              <td>
                {!t.verified && (
                  <button className="btn-verify" onClick={() => handleVerifyTip(t.id)}>Verify & Award</button>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );

  const renderAnalytics = () => (
    <div className="analytics-grid">
      <div className="chart-card">
        <h3><FiAlertCircle /> Urgency Distribution</h3>
        <div className="chart-wrapper">
            <Doughnut 
              data={urgencyData} 
              options={{ 
                maintainAspectRatio: false, 
                plugins: { 
                  legend: { position: 'bottom', labels: { usePointStyle: true, padding: 20 } } 
                } 
              }} 
            />
        </div>
      </div>
      <div className="chart-card">
        <h3><FiTrendingUp /> Case Status Overview</h3>
        <div className="chart-wrapper">
            <Bar data={statusData} />
        </div>
      </div>
    </div>
  );

  const renderHonour = () => (
    <div className="table-container">
      <h2>Honour System Management</h2>
      <table>
        <thead>
          <tr>
            <th>User</th>
            <th>Score</th>
            <th>Medals</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody>
          {users.length === 0 ? (
            <tr><td colSpan="4" className="empty-state">No users in the honour system yet.</td></tr>
          ) : users.map(u => (
            <tr key={u.id}>
              <td>{u.name}</td>
              <td>{u.score}</td>
              <td>{u.medals.join(', ')}</td>
              <td>
                <button className="btn-cert">Issue Certificate</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );

  if (isLoading) {
    return (
      <div className="loading-container">
        <FiLoader className="spinner" size={50} />
        <p>Loading RESQLINK Dashboard...</p>
      </div>
    );
  }

  return (
    <div className="dashboard">
      <div className="sidebar">
        <div className="logo">RESQLINK Admin</div>
        <nav>
          <button className={activeTab === 'overview' ? 'active' : ''} onClick={() => setActiveTab('overview')}><FiGrid /><span>Dashboard</span></button>
          <button className={activeTab === 'cases' ? 'active' : ''} onClick={() => setActiveTab('cases')}><FiCheckSquare /><span>Case Management</span></button>
          <button className={activeTab === 'tips' ? 'active' : ''} onClick={() => setActiveTab('tips')}><FiMessageSquare /><span>Tip Monitoring</span></button>
          <button className={activeTab === 'analytics' ? 'active' : ''} onClick={() => setActiveTab('analytics')}><FiBarChart2 /><span>Analytics</span></button>
          <button className={activeTab === 'honour' ? 'active' : ''} onClick={() => setActiveTab('honour')}><FiAward /><span>Honour System</span></button>
        </nav>
      </div>
      <div className="main-content">
        <header>
          <h1>{activeTab.charAt(0).toUpperCase() + activeTab.slice(1)}</h1>
          <div className="user-profile">
            <span className="update-time">
              Last updated: {lastUpdated.toLocaleTimeString()}
            </span>
            <div className="admin-avatar">A</div>
          </div>
        </header>
        <div className="content-area">
          {activeTab === 'overview' && renderOverview()}
          {activeTab === 'cases' && renderCases()}
          {activeTab === 'tips' && renderTips()}
          {activeTab === 'analytics' && renderAnalytics()}
          {activeTab === 'honour' && renderHonour()}
        </div>
      </div>
    </div>
  );
};

export default Dashboard;