import type { Metadata } from "next";
import "./globals.css";
import "./masters.css";
import "./operations.css";
import "./receptions.css";
import "./finance.css";
import "./corrections.css";
import "./dashboard.css";
import "./admin.css";
import "./quality.css";
export const metadata: Metadata = { title:"ERP Familia", description:"Gestión frutícola" };
export default function RootLayout({children}:{children:React.ReactNode}) { return <html lang="es"><body>{children}</body></html>; }

