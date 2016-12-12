# Recipe name: start_xvfb
#
# This will start Xvfb in the background and export DISPLAY to :99
#

bash 'start Xvfb in background' do
  code <<-EOH
    Xvfb -ac :99 -screen 0 1280x1024x16 &
    export DISPLAY=:99
  EOH
end

