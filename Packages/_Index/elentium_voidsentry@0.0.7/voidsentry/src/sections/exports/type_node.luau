export type typeNode = {
	name: string,
	write: (value: any) -> (),
	read: (b: buffer, cursor: number) -> (any, number),
}
return {}
