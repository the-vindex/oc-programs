print("Unloading")
for moduleName, _ in pairs(package.loaded) do
  if package.loaded[moduleName].___unload then
    package.loaded[moduleName] = nil
  end
end
