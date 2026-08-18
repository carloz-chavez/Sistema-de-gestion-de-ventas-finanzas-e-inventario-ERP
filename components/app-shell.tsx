import { Sidebar } from "./sidebar";
export function AppShell({children}:{children:React.ReactNode}) { return <div className="shell"><Sidebar/><main>{children}</main></div>; }

