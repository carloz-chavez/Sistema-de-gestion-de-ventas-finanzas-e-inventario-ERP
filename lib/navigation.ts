import { Boxes, CircleDollarSign, ClipboardCheck, House, Settings, ShoppingCart, Truck, Warehouse } from "lucide-react";

export const navigation = [
  { label: "Inicio", href: "/inicio", icon: House },
  { label: "Producción", href: "/produccion", icon: Boxes },
  { label: "Envíos", href: "/envios", icon: Truck },
  { label: "Recepciones", href: "/recepciones", icon: ClipboardCheck },
  { label: "Ventas", href: "/ventas", icon: ShoppingCart },
  { label: "Finanzas", href: "/finanzas", icon: CircleDollarSign },
  { label: "Maestros", href: "/maestros", icon: Warehouse },
  { label: "Administración", href: "/administracion", icon: Settings },
] as const;

export const masterPaths = ["/productores", "/clientes", "/trabajadores", "/transportistas", "/materiales"];

