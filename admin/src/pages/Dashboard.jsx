import Sidebar from "../components/Sidebar";
import Navbar from "../components/Navbar";
import StatCard from "../components/StatCard";
import "../styles/dashboard.css";

import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend,
} from "chart.js";

import { Bar } from "react-chartjs-2";

ChartJS.register(
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend
);

const Dashboard = () => {
  const stats = {
    total: 120,
    pending: 15,
    active: 70,
    found: 25,
    critical: 10,
  };

  const data = {
    labels: ["Pending", "Active", "Found"],
    datasets: [
      {
        label: "Cases",
        data: [stats.pending, stats.active, stats.found],
        backgroundColor: ["orange", "red", "green"],
      },
    ],
  };

  return (
    <div className="container">
      <Sidebar />

      <div className="main">
        <Navbar />

        <div className="cards">
          <StatCard title="Total Reports" value={stats.total} />
          <StatCard title="Pending" value={stats.pending} />
          <StatCard title="Active" value={stats.active} />
          <StatCard title="Found" value={stats.found} />
          <StatCard title="Critical" value={stats.critical} />
        </div>

        <div className="chart-container">
          <Bar data={data} />
        </div>
      </div>
    </div>
  );
};

export default Dashboard;