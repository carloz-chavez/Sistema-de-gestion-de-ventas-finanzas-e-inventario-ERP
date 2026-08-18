import { Sidebar } from "./sidebar";
import { SafetyNet } from "./safety-net";
export function AppShell({children}:{children:React.ReactNode}) { return <div className="shell"><SafetyNet/><Sidebar/><main>{children}</main></div>; }

