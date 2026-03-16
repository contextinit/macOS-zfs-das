import { useState, useEffect } from 'react';
import { loadAnalytics, hasConsent } from '../../utils/analytics';

const CONSENT_KEY = 'analytics_consent';

export default function CookieBanner() {
    const [visible, setVisible] = useState(false);

    useEffect(() => {
        // Only show if the user hasn't decided yet
        if (!localStorage.getItem(CONSENT_KEY)) {
            setVisible(true);
        }
    }, []);

    const accept = () => {
        localStorage.setItem(CONSENT_KEY, 'granted');
        setVisible(false);
        loadAnalytics();
    };

    const decline = () => {
        localStorage.setItem(CONSENT_KEY, 'denied');
        setVisible(false);
    };

    if (!visible) return null;

    return (
        <div
            role="dialog"
            aria-live="polite"
            aria-label="Cookie consent"
            className="fixed bottom-0 left-0 right-0 z-50 p-4 bg-gray-900 border-t border-gray-700 shadow-2xl"
        >
            <div className="max-w-7xl mx-auto flex flex-col sm:flex-row items-start sm:items-center gap-4">
                <p className="flex-1 text-sm text-gray-300">
                    We use Google Analytics to understand how visitors use this site.
                    No personally identifiable information is collected.{' '}
                    <a
                        href="/privacy"
                        className="text-primary-400 hover:text-primary-300 underline"
                    >
                        Privacy Policy
                    </a>
                </p>
                <div className="flex gap-3 flex-shrink-0">
                    <button
                        onClick={decline}
                        className="px-4 py-2 text-sm font-medium text-gray-300 border border-gray-600 rounded-lg hover:bg-gray-800 transition"
                    >
                        Decline
                    </button>
                    <button
                        onClick={accept}
                        className="px-4 py-2 text-sm font-medium text-white bg-primary-600 rounded-lg hover:bg-primary-700 transition"
                    >
                        Accept
                    </button>
                </div>
            </div>
        </div>
    );
}
