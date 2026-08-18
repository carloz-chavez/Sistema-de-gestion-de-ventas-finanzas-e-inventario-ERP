import { updateReception } from "@/app/actions";
type Row=Record<string,unknown>;
export function ReceptionCorrection({row}:{row:Row}){return row.estado==="BORRADOR"?<div className="correctionBox"><h3>Corregir cantidades</h3><form action={updateReception} className="correctionForm receptionCorrection"><input type="hidden" name="id" value={String(row.id)}/><label>Aceptadas<input name="cantidad_aceptada" type="number" min="0" defaultValue={Number(row.cantidad_aceptada)}/></label><label>Rechazadas<input name="cantidad_rechazada" type="number" min="0" defaultValue={Number(row.cantidad_rechazada)}/></label><label>Observaciones<input name="observaciones" defaultValue={String(row.observaciones||"")}/></label><button className="secondary">Guardar corrección</button></form></div>:null}

