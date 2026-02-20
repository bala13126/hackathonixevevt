import "../styles/dashboard.css";

const Sidebar = () => {
  return (
    <div className="sidebar">
      <h2>HX-50 Admin</h2>
      <ul>
        <li>Dashboard</li>
        <li>Pending Cases</li>
        <li>Active Cases</li>
        <li>Tips</li>
        <li>Users</li>
      </ul>
    </div>
  );
};

export default Sidebar;