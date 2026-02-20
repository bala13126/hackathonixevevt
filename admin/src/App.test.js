import { render } from '@testing-library/react';
import App from './App';

// Mock ResizeObserver which is not available in JSDOM but required by Chart.js
global.ResizeObserver = class ResizeObserver {
  observe() {}
  unobserve() {}
  disconnect() {}
};

// Mock global fetch for API calls
global.fetch = jest.fn(() =>
  Promise.resolve({
    ok: true,
    json: () => Promise.resolve([]),
  })
);

test('renders App component without crashing', () => {
  render(<App />);
});
