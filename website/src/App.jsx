import { BrowserRouter as Router, Routes, Route, useLocation } from 'react-router-dom';
import { useEffect } from 'react';
import { trackPageView } from './utils/analytics';
import Navbar from './components/layout/Navbar';
import Footer from './components/layout/Footer';
import CookieBanner from './components/common/CookieBanner';
import ErrorBoundary from './components/common/ErrorBoundary';
import Home from './pages/Home';
import GettingStarted from './pages/GettingStarted';
import Wizards from './pages/Wizards';
import Documentation from './pages/Documentation';
import Download from './pages/Download';

function ScrollToTop() {
    const { pathname, hash } = useLocation();

    useEffect(() => {
        if (hash) {
            setTimeout(() => {
                const element = document.querySelector(hash);
                if (element) {
                    element.scrollIntoView({ behavior: 'smooth' });
                }
            }, 100);
        } else {
            window.scrollTo(0, 0);
        }
    }, [pathname, hash]);

    return null;
}

function PageTracker() {
    const location = useLocation();

    useEffect(() => {
        trackPageView(location.pathname + location.search + location.hash, document.title);
    }, [location]);

    return null;
}

function App() {
    return (
        <Router>
            <ErrorBoundary>
                <ScrollToTop />
                <PageTracker />
                <div className="flex flex-col min-h-screen bg-gray-50">
                    <Navbar />
                    <main className="flex-grow">
                        <Routes>
                            <Route path="/" element={<Home />} />
                            <Route path="/getting-started" element={<GettingStarted />} />
                            <Route path="/wizards/*" element={<Wizards />} />
                            <Route path="/docs/*" element={<Documentation />} />
                            <Route path="/download" element={<Download />} />
                            <Route path="*" element={
                                <div className="min-h-screen flex items-center justify-center bg-gray-50 px-4">
                                    <div className="text-center">
                                        <h1 className="text-6xl font-bold text-gray-900 mb-4">404</h1>
                                        <p className="text-xl text-gray-600 mb-8">Page not found</p>
                                        <a href="/" className="btn btn-primary">Go Home</a>
                                    </div>
                                </div>
                            } />
                        </Routes>
                    </main>
                    <Footer />
                    <CookieBanner />
                </div>
            </ErrorBoundary>
        </Router>
    );
}

export default App;
