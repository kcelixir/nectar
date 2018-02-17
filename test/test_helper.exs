# Load but don't start application
Application.load(:nectar)

# Start application's dependencies
for app <- Application.spec(:nectar, :applications) do
  Application.ensure_all_started(app)
end

ExUnit.start()
