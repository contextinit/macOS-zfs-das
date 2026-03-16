import { useState } from 'react';
import { ClipboardDocumentIcon, CheckIcon } from '@heroicons/react/24/outline';
import { trackCopyCommand } from '../../../utils/analytics';

export default function CommandBlock({ command, language = 'bash' }) {
    const [copied, setCopied] = useState(false);

    const handleCopy = async () => {
        try {
            await navigator.clipboard.writeText(command);
            setCopied(true);
            trackCopyCommand(command);
            setTimeout(() => setCopied(false), 2000);
        } catch {
            setCopied('error');
            setTimeout(() => setCopied(false), 2000);
        }
    };

    return (
        <div className="relative group">
            <div className="command-block">
                <pre className="language-{language}">
                    <code>{command}</code>
                </pre>
            </div>

            <button
                onClick={handleCopy}
                aria-label="Copy to clipboard"
                className="absolute top-2 right-2 p-2 rounded-lg bg-gray-800 hover:bg-gray-700 text-gray-300 hover:text-white transition-all opacity-0 group-hover:opacity-100"
                title="Copy to clipboard"
            >
                {copied === 'error' ? (
                    <span className="text-sm text-red-400">Copy failed</span>
                ) : copied ? (
                    <div className="flex items-center space-x-1">
                        <CheckIcon className="w-5 h-5 text-green-400" />
                        <span className="text-sm">Copied!</span>
                    </div>
                ) : (
                    <ClipboardDocumentIcon className="w-5 h-5" />
                )}
            </button>
        </div>
    );
}
