export default function Card({ children, className = '', hover = true, ...props }) {
    return (
        <div
            className={`card ${hover ? 'hover:scale-102' : ''} ${className}`}
            {...props}
        >
            {children}
        </div>
    );
}
