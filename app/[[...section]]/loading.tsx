export default function Loading(){return <div className="loadingPage" role="status" aria-label="Cargando"><div className="loadingHead"/><div className="loadingStats">{[1,2,3,4].map(x=><span key={x}/>)}</div><div className="loadingPanel"/><p>Cargando información…</p></div>}

