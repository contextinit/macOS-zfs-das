import { Component } from 'react';

export default class ErrorBoundary extends Component {
    constructor(props) {
        super(props);
        this.state = { hasError: false };
    }

    static getDerivedStateFromError() {
        return { hasError: true };
    }

    render() {
        if (this.state.hasError) {
            return (
                <div className="min-h-screen flex items-center justify-center bg-gray-50 px-4">
                    <div className="text-center max-w-md">
                        <h1 className="text-4xl font-bold text-gray-900 mb-4">Something went wrong</h1>
                        <p className="text-gray-600 mb-8">
                            An unexpected error occurred. Please refresh the page or{' '}
                            <a href="/" className="text-primary-600 hover:text-primary-700 underline">
                                return home
                            </a>.
                        </p>
                        <button
                            onClick={() => window.location.reload()}
                            className="px-6 py-3 bg-primary-600 text-white font-medium rounded-lg hover:bg-primary-700 transition"
                        >
                            Refresh page
                        </button>
                    </div>
                </div>
            );
        }
        return this.props.children;
    }
}
