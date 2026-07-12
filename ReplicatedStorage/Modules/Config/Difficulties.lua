--!strict
-- Difficulties — every playable preset. Pure data, no functions.

export type DifficultyPreset = {
	Name: string,
	Label: string,
	Desc: string,
	Width: number,
	Height: number,
	Mines: number,
}

local Difficulties: { [string]: DifficultyPreset } = {}

Difficulties.Easy = {
	Name = "Easy",
	Label = "Fácil",
	Desc = "9×9 · 10 minas",
	Width = 9,
	Height = 9,
	Mines = 10,
}

Difficulties.Normal = {
	Name = "Normal",
	Label = "Normal",
	Desc = "16×16 · 40 minas",
	Width = 16,
	Height = 16,
	Mines = 40,
}

Difficulties.Hard = {
	Name = "Hard",
	Label = "Difícil",
	Desc = "32×32 · 200 minas",
	Width = 32,
	Height = 32,
	Mines = 200,
}

Difficulties.List = {
	Difficulties.Easy,
	Difficulties.Normal,
	Difficulties.Hard,
}

return Difficulties
