"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
const tabs=[
  ["Productores","/productores"],["Clientes","/clientes"],["Trabajadores","/trabajadores"],
  ["Transportistas","/transportistas"],["Materiales","/materiales"],["Productos","/productos"],
  ["Variedades","/variedades"],["Motivos de rechazo","/motivos-rechazo"],["Categorías de gasto","/categorias-gasto"],
] as const;
export function MasterTabs(){const pathname=usePathname();return <nav className="masterTabs" aria-label="Secciones de maestros">{tabs.map(([label,href])=><Link key={href} href={href} className={pathname===href?"selected":""}>{label}</Link>)}</nav>}

