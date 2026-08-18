"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { LogOut, Sprout } from "lucide-react";
import { masterPaths, navigation } from "@/lib/navigation";

export function Sidebar() {
  const pathname = usePathname();
  return <aside className="sidebar">
    <div className="brand"><span className="brandIcon"><Sprout size={22}/></span><div><strong>ERP Familia</strong><small>Gestión frutícola</small></div></div>
    <nav aria-label="Navegación principal">{navigation.map(({label,href,icon:Icon}) => {
      const active = pathname === href || (href === "/maestros" && masterPaths.includes(pathname));
      return <Link className={`navItem ${active ? "active" : ""}`} href={href} key={href}><Icon size={19}/><span>{label}</span></Link>;
    })}</nav>
    <div className="user"><span className="avatar">CD</span><div><strong>Carlos Daniel</strong><small>Administrador</small></div><button aria-label="Cerrar sesión"><LogOut size={17}/></button></div>
  </aside>;
}

