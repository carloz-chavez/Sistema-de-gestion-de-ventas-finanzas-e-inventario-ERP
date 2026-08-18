"use client";
import Link from "next/link";
import { AlertTriangle, RotateCcw } from "lucide-react";
export default function ErrorPage({error,reset}:{error:Error&{digest?:string};reset:()=>void}){const raw=error.message||"";const message=raw.includes("motivos de rechazo")?raw:raw.includes("saldo")||raw.includes("anular")||raw.includes("administrador")||raw.includes("lote")?raw:"No pudimos completar la operación. Revisa los datos e inténtalo nuevamente.";return <main className="friendlyError"><section className="panel"><span className="errorIcon"><AlertTriangle/></span><p className="eyebrow">La operación necesita atención</p><h1>No se realizaron todos los cambios</h1><p>{message}</p><div className="errorActions"><button className="primary" onClick={reset}><RotateCcw size={15}/> Intentar nuevamente</button><Link className="secondary" href="/inicio">Volver al inicio</Link></div>{error.digest?<small>Referencia: {error.digest}</small>:null}</section></main>}

