namespace :claude do
  desc "Show current task and context"
  task :status => :environment do
    puts "\n📋 CURRENT STATUS"
    puts "=" * 50
    
    if File.exist?('TASKS.md')
      tasks = File.read('TASKS.md')
      current = tasks.match(/\[@current\](.+)$/)
      puts "Current Task: #{current ? current[1] : 'No task set'}"
    end
    
    puts "\nTheme Status:"
    if Dir.exist?('app/views/themes/backstage_pass')
      puts "  ✅ Theme ejected and ready"
    else
      puts "  ❌ Theme NOT ejected - cannot edit views!"
    end
    
    puts "\nGems Status:"
    ['magic_test', 'livekit-server-sdk', 'mux-ruby'].each do |gem|
      if system("grep -q '#{gem}' Gemfile.lock", out: File::NULL)
        puts "  ✅ #{gem} installed"
      else
        puts "  ❌ #{gem} missing"
      end
    end
  end
  
  desc "Move to next task"
  task :next => :environment do
    if File.exist?('TASKS.md')
      content = File.read('TASKS.md')
      content.gsub!(' (@current)', '')
      
      if content =~ /- \[ \] (.+)$/
        next_task = $1
        content.sub!("- [ ] #{next_task}", "- [ ] #{next_task} (@current)")
        File.write('TASKS.md', content)
        puts "📍 Next task: #{next_task}"
      end
    end
  end
end
