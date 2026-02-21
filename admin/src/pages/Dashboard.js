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

const API_BASE_URL = process.env.REACT_APP_API_BASE_URL || 'http://127.0.0.1:8000/api';

const Dashboard = () => {
  const [activeTab, setActiveTab] = useState('overview');

  // Real-time Data State
  const [cases, setCases] = useState([]);
  const [tips, setTips] = useState([]);
  const [users, setUsers] = useState([]);
  const [lastUpdated, setLastUpdated] = useState(new Date());
  const [isLoading, setIsLoading] = useState(true);
  const [rewards, setRewards] = useState([]);
  const [redemptions, setRedemptions] = useState([]);
  const [reports, setReports] = useState([]);
  const [pointsAdjustments, setPointsAdjustments] = useState({});

  // API Configuration
  // Fetch Data (Polling for real-time updates)
  useEffect(() => {
    const fetchData = async () => {
      try {
        const [casesRes, tipsRes, usersRes, rewardsRes, redemptionsRes, reportsRes] = await Promise.all([
          fetch(`${API_BASE_URL}/cases`),
          fetch(`${API_BASE_URL}/tips`),
          fetch(`${API_BASE_URL}/users`),
          fetch(`${API_BASE_URL}/rewards`),
          fetch(`${API_BASE_URL}/rewards/redemptions`),
          fetch(`${API_BASE_URL}/reports/`)
        ]);

        if (casesRes.ok) setCases(await casesRes.json());
        if (tipsRes.ok) setTips(await tipsRes.json());
        if (usersRes.ok) setUsers(await usersRes.json());
        if (rewardsRes.ok) setRewards(await rewardsRes.json());
        if (redemptionsRes.ok) setRedemptions(await redemptionsRes.json());
        if (reportsRes.ok) setReports(await reportsRes.json());
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

  const handleRedemptionReview = async (id, status) => {
    setRedemptions(redemptions.map(r => r.id === id ? { ...r, status } : r));

    try {
      await fetch(`${API_BASE_URL}/rewards/redemptions/${id}/review`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status }),
      });
    } catch (error) {
      console.error('Failed to review redemption:', error);
    }
  };

  const handleReportReview = async (id, status) => {
    setReports(reports.map(r => r.id === id ? { ...r, status } : r));

    try {
      await fetch(`${API_BASE_URL}/reports/${id}/review/`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status }),
      });
    } catch (error) {
      console.error('Failed to review report:', error);
    }
  };

  const handlePointsChange = (userId, value) => {
    setPointsAdjustments(prev => ({ ...prev, [userId]: value }));
  };

  const handleAwardPoints = async (userId, mode = 'add') => {
    const rawValue = pointsAdjustments[userId];
    const points = Number(rawValue);
    if (!Number.isFinite(points)) {
      alert('Please enter a valid number');
      return;
    }

    try {
      const res = await fetch(`${API_BASE_URL}/users/${userId}/points`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ points, mode }),
      });
      if (!res.ok) {
        throw new Error('Failed to update points');
      }
      const updated = await res.json();
      setUsers(users.map(u => (u.id === userId ? updated : u)));
      setPointsAdjustments(prev => ({ ...prev, [userId]: '' }));
      alert(`Points ${mode === 'add' ? 'added' : 'set'} successfully! New score: ${updated.score}`);
    } catch (error) {
      console.error('Failed to update points:', error);
      alert(`Failed to update points: ${error.message}`);
    }
  };

  const urgencyScore = (caseItem) => {
    const urgencyWeight = caseItem.urgency === 'High' ? 1 : caseItem.urgency === 'Medium' ? 0.7 : 0.4;
    const hoursAgo = Math.max(
      0,
      (Date.now() - new Date(caseItem.created_at).getTime()) / (1000 * 60 * 60)
    );
    const recency = Math.max(0, 1 - hoursAgo / 72);
    return (urgencyWeight * 0.65 + recency * 0.35).toFixed(2);
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
      <div className="stat-card">
        <div>
          <h3>Rewards</h3>
          <p>{rewards.length}</p>
        </div>
        <div className="stat-icon icon-blue">
          <FiAward size={24} />
        </div>
      </div>
      <div className="stat-card">
        <div>
          <h3>Sighting Reports</h3>
          <p>{reports.length}</p>
        </div>
        <div className="stat-icon icon-orange">
          <FiAlertCircle size={24} />
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
            <th>Urgency Score</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {cases.length === 0 ? (
            <tr><td colSpan="7" className="empty-state">No cases to display.</td></tr>
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
              <td>{urgencyScore(c)}</td>
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
            <th>Points</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody>
          {users.length === 0 ? (
            <tr><td colSpan="5" className="empty-state">No users in the honour system yet.</td></tr>
          ) : users.map(u => (
            <tr key={u.id}>
              <td>{u.name}</td>
              <td>{u.score}</td>
              <td>{u.medals.join(', ')}</td>
              <td>
                <input
                  className="points-input"
                  type="number"
                  placeholder="+10"
                  value={pointsAdjustments[u.id] ?? ''}
                  onChange={(event) => handlePointsChange(u.id, event.target.value)}
                />
              </td>
              <td>
                <button className="btn-approve" onClick={() => handleAwardPoints(u.id, 'add')}>Add</button>
                <button className="btn-reject" onClick={() => handleAwardPoints(u.id, 'set')}>Set</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );

  const renderRewards = () => (
    <div className="table-container">
      <h2>Rewards & Redemptions</h2>
      <table>
        <thead>
          <tr>
            <th>Reward</th>
            <th>Points</th>
            <th>Status</th>
            <th>Requested By</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody>
          {redemptions.length === 0 ? (
            <tr><td colSpan="5" className="empty-state">No redemptions yet.</td></tr>
          ) : redemptions.map(r => (
            <tr key={r.id}>
              <td>{r.rewardName || r.reward}</td>
              <td>{rewards.find(rew => rew.id === r.reward)?.points_required ?? '-'}</td>
              <td>
                <span className={`status-badge ${r.status.toLowerCase()}`}>{r.status}</span>
              </td>
              <td>{r.userName || `User #${r.userId}`}</td>
              <td>
                {r.status === 'Pending' && (
                  <>
                    <button className="btn-approve" onClick={() => handleRedemptionReview(r.id, 'Approved')}>Approve</button>
                    <button className="btn-reject" onClick={() => handleRedemptionReview(r.id, 'Rejected')}>Reject</button>
                  </>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );

  const renderSightings = () => (
    <div className="table-container">
      <h2>Sighting Reports</h2>
      <table>
        <thead>
          <tr>
            <th>Case</th>
            <th>Reporter</th>
            <th>Summary</th>
            <th>Location</th>
            <th>Status</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody>
          {reports.length === 0 ? (
            <tr><td colSpan="6" className="empty-state">No sighting reports yet.</td></tr>
          ) : reports.map(r => (
            <tr key={r.id}>
              <td>#{r.missing_case_id}</td>
              <td>{r.reporter_name || 'Anonymous'}</td>
              <td>{r.description?.slice(0, 80)}{r.description?.length > 80 ? '...' : ''}</td>
              <td>{r.latitude?.toFixed(3)}, {r.longitude?.toFixed(3)}</td>
              <td>
                <span className={`status-badge ${r.status.toLowerCase()}`}>{r.status}</span>
              </td>
              <td>
                {r.status === 'Pending' && (
                  <>
                    <button className="btn-approve" onClick={() => handleReportReview(r.id, 'Accepted')}>Accept</button>
                    <button className="btn-reject" onClick={() => handleReportReview(r.id, 'Rejected')}>Reject</button>
                  </>
                )}
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
          <button className={activeTab === 'rewards' ? 'active' : ''} onClick={() => setActiveTab('rewards')}><FiAward /><span>Rewards</span></button>
          <button className={activeTab === 'sightings' ? 'active' : ''} onClick={() => setActiveTab('sightings')}><FiAlertCircle /><span>Sightings</span></button>
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
          {activeTab === 'rewards' && renderRewards()}
          {activeTab === 'sightings' && renderSightings()}
        </div>
      </div>
    </div>
  );
};

export default Dashboard;