-- 0.2.0: recepty tierů odemyká vlastní výzkum tieru místo výzkumu pásu / fast inserteru.
-- Přepočítá odemčené recepty podle vyzkoumaných výzkumů, jinak by recept zůstal odemčený i bez nového výzkumu.
for _, force in pairs(game.forces) do
  force.reset_technology_effects()
end
