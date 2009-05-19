# ex: set ts=4 et:
require "net/http"
require "cgi"

# Slashdot Headline Generator
# keep nerds happy on those long network outages
# by pizza

class SlashdotHeadlineGenerator < ModSpox::Plugin

    def initialize(pipeline)
        super
        add_sig(:sig => 'fake/.( (\d))?', :method => :random, :desc => 'Slashdot Headline Generator', :params => [:wspace, :count])
    end
    
    def random(m, params)
        begin
            params[:count] = 1 if params[:count].nil?
            params[:count] = 1 if params[:count] < 1
            params[:count] = 5 if params[:count] > 5
            say = ""
            params[:count].times { say += headline() + "\n" }
            reply m.replyto, say
        rescue Object => boom
            error m.replyto, "Whoops. #{boom}"
        end
    end
    
    def headline()
        any([
            #Apache,
            lambda{ Apple() },
            lambda{ AskSlashdot() },
            #BackSlash,
            lambda{ BookReview() },
            lambda{ BSD() },
            lambda{ Business() },
            lambda{ Developers() },
            #Entertainment,
            #Features,
            lambda{ Games() },
            #GeeksInSpace,
            lambda{ Hardware() },
            #Idle,
            lambda{ Interviews() },
            lambda{ IT() },
            lambda{ Linux() },
            #Media,
            lambda{ News() },
            #Polls,
            #Politics,
            lambda{ Science() },
            #Search,
            lambda{ Technology() },
            lambda{ YourRightsOnline() }
        ]).call
    end

def Apple()
  foo = rand(2+1-0)
  if foo == 0
    "New " + AppleProduct() + " Release Features " + GoodBrowserFeature()
  elsif foo == 1
    "Apple " + AppleHireFire()
  else
    "Turn Your " + AppleHardware() + " Into A " + any([ "Fishbowl", "Phaser", "RC Car", "Robot", "Webserver", "Vibrator", "Calculator" ])
  end
end

def AppleHireFire()
  any([ "Hires", "Re-Hires", "Eying" ]) + [ " Former", ""][rand(2)] + " " + TechCompany() + " " + Profession()
end

def AppleProduct() any([ lambda{ AppleSoftware() }, lambda{ AppleHardware() } ]).call; end
def AppleSoftware() any([ "OS9", "OS X", "iTunes", "iLife", "SnowLeopard", "Cheetah", "Panther" ]); end
def AppleHardware() any([ "iMac", "iPod", "iPhone", "MacBook" ]); end

def AskSlashdot()
  any([ "Encrypting", "Porting", "Taking Over", "Forking", "Selling", "Buying", "Saving", "Archiving" ]) + " " +
  any([ "Abandoned", "Open Source", "Free", "Slow", "Closed Source", "Web-based", "Obsolete" ]) + " " +
  any([ "Hardware", "Software", "Projects", "Drivers", "Operating Systems", "Frameworks", "Programming Languages", "Coffee Machines", "Missile Guidance Software", "Filesystems", "Media" ]) + "?"
end

def BookReview() "Book Review:" + TechnoAdjective() + " " + ProgrammingLanguageOrFramework() end

def BSD()
  os = NerdOS()
  os + " " + OSVersion(os) + " " + NerdOSSuffix()
end

def Business()
  foo = rand(5)
  if foo == 0
    Google()
  elsif foo == 1
    Microsoft()
  elsif foo == 2
    TechCompany() + " Unveils Potential " + VenerableProduct() + " Killer"
  elsif foo == 3
    TechCompany() + " " +
      any([ "Considering", "Possibly" ]) + " "
      any([ "Purchasing", "Alliance with", "Merging with"]) + " " +
      TechCompany() + "?"
  else
    TechCompany() + " Patents " + Patentable()
  end
end

def Developers() any([ lambda{ MozillaDitchFeature() }, lambda{ IsDead() }, lambda{ BugPatched() }, lambda{ GNU() } ]).call; end

def IsDead() "Are " + NerdTopic() + "s " + DeadWords() + "?"; end
def BugPatched() LongTime()[0..-2] +"-Old Bug Discovered in " + NerdOS() + ", Patched in " + ShortTime() + "s"; end
def GNU() any([ lambda{ Stallman() } ]).call; end
def Stallman()
  "Richard Stallman " +
  any([ "Slams", "Decries", "Demonizes" ]) +
  " Use of " +
  any([ "Closed-Source", "Proprietary", "Web-based", "Ascii-Only", "Unicode", "English-Only" ]) + " " +
  any([ "Software", "Hardware", "Firmware", "USB Sticks", "CDs", "Operating Systems" ]) +
  " As " +
  any([ "Capitalistic", "Fundamentally Unfree", "Stupid", "'Worse Than Hitler'" ])
end

def Games()
  Game() + " " +
  any([ "Breaks Everyone's Favorite", "Enhances", "Features New", "Promises Better", "Reconsiders", "Redesigns", "Restricts", "Rethinks", "Will Change How You Think About" ]) + " " +
  any(["AI", "Weapons", "Cheats", "Controls", "Easter Eggs", "Graphics", "Levels", "Team-based Cooperation" ])
end

def Hardware() 
  any([ "ATI", "NVidia", "Open Source Graphics Collective" ]) + " " +
  any([ "Secretly", "Purportedly", "Possibly", "Admittedly" ]) + " " +
  any([ "Considers", "Cancels", "Reveals" ]) + " " +
  any([ "Porting", "Adding Pipelines to", "Adding Cores to", "Open Sourcing", "New Features in", "Adding Shaders to", "Adding Raytracing to", "Upgrade to", "Production of" ]) + " " +
  RandomGraphicsCardProduct()
end

def GraphicsPrefix() any([ "Open", "Phys", "GP", "Direct" ]); end
def GraphicsSuffix() any([ "X", "GL", "Gfx" ]); end
def RandomGraphicsCardProduct() GraphicsPrefix() + GraphicsSuffix() + [ "", ((rand(7)+2)*100).to_s ][rand(2)]; end

def IT() 
  foo = rand(2)
  if foo == 0
    TechnoAdjective() + " " +
    any([ "Programming", "Studying", "Training", "Administration" ]) + " " +
    any([ "Rituals", "Secrets", "Habits", "Theories", "Stories", "Experiences", "Close Calls" ])
  else
    "What's Your Favorite " + NerdTopic() + "?"
  end
end

def Game() GameTitle() + " " + GameVersion() end
def GameTitle() any([ "Quake", "Doom", "The Sims", "Half-Life", "Call of Duty", "Warcraft", "TeamFortress", "Halo", "Guitar Hero", "Grand Theft Auto", "Final Fantasy" ]); end

def Interviews() "Ask " + TechOrganization() + " " + Profession() + " " + RandomName() end

def Linux() any([ lambda{ LinuxOS() }, lambda{ TorvaldsQuote() } ]).call; end

def LinuxOS() "Linux " + LinuxVersion() + " " + NerdOSSuffix() end
def LinuxVersion() "2.6." + (rand(185)+15).to_s; end

def TorvaldsQuote()
  "Torvalds to " +
  any([ "Users", "Administrators", "Everyone", "the Media", "Long-time Contributors", "Linux Volunteers", "Hard-working Subsystem Maintainers", "Linux Community" ]) + " " +
  any([ "Piss Off!", "You're All Stupid", "Bite Me", "You Are Idiots", "Shut Up" ])
end

def News() any([ lambda{ WebsiteOutage() }, lambda{ InaneNewsQuestion() } ]).call; end

def InaneNewsQuestion()
  any([ "Do We Really Want", "Do We Really Need", "Don't We Have Enough" ]) + " " +
  any([ "ISPs", "Vendors", "Software Companies", "Monopolies", "Advertisers", "DRM", "Watermarks", "Trademarks" ]) + " " +
  any([ "Filtering", "In", "Monitoring", "Embedded in" ]) + " " +
  any([ "Desktops", "Software", "the Workplace", "Entertainment", "Source Code", "Networks", "Schools", "Games" ]) + "?"
end

def Science() any([ lambda{ Physics() }, lambda{ Math() }, lambda{ Science() } ]).call; end

def Technology() any([ lambda{ SoftwareVS() }, lambda{ Top10() } ]).call; end

def SoftwareVS() SoftwareProduct() + " " + any([ "Takes On", "vs.", "Now Supports", "Drops Support for" ]) + " " + any([ "PDF", "Graphics", "Plaintext", "the Internet", "Email", "Unicode" ]); end

def Top10()
  "Top 10 " +
  any([ "Hottest", "Disastrous", "Best", "Worst", "Biggest", "Stupidest" ]) + " " +
  any([ "Applications", "Operating Systems", "Programming Languages", "IDEs", "Debuggers", "PCs", "Products", "Technologies", "Decisions in Software" ])
end

def SoftwareProduct() any([ "MS Word", "Excel", "Visio", "Acrobat", "Photoshop", "Lotus Notes", "OpenOffice", "GNU Cash" ]); end
def YourRightsOnline() any([ lambda{ Encryption() }, lambda{ FileSharing() }, lambda{ UserDataStolen() }, lambda{ TinfoilHat() } ]).call; end
def Encryption() "Researchers Break " + TechnoRate() + " " + any(["Encryption", "Transmission", "Internet2" ]) + " Record"; end

def UserDataStolen()
  any([ "Bank", "Corporation", "University", "Government", "Military" ]) + " " +
  any([ "Misplaces USB Stick Containing", "Loses Harddrives Containing", "Sells Tape Drive Containing", "Mistakenly Gives Away", "Website Exposes" ]) + " " +
  (rand(500)).to_s + " Million " +
  any([ "Credit Card Numbers", "Social Security Numbers", "User Passwords" ])
end

def TinfoilHat()
  any([
    "Is " + (rand(20)+5).to_s + "-Gauge Tinfoil Really Thick Enough?",
    GovOrg() + " Monitors Your " + PersonalThing(),
    "Encrypting Your " + PersonalThing() + " Won't Thwart " + GovOrg(),
    "Wouldn't " + any([ "You", "Aliens", "Your Mom", "Your Grandmother", "Your Boss" ]) + " Use " + NerdOS() + "?"
  ])
end

def Microsoft()
  any([
    lambda{ Windows() },
    lambda{ WindowsUpdate() },
    lambda{ MicrosoftEvil() },
    lambda{ MicrosoftRandom() }
  ]).call
end

def Windows() WindowsPrefix() + " Windows " + WindowsVersion() end

def MicrosoftEvil()
  "Microsoft's " +
    any([ "Patents", "Pricing Policies", "Monopolistic Tactics", "Insecure Software", "High Prices" ]) + " " +
    any([ "Crippling", "Destroying", "Maiming", "Hurting", "Poisoning", "Degrading" ]) + " " +
    any([ "the Internet", "Operating Systems", "the Software Industry", "Society", "Open Source", "Blind Children", "Communities", "the Environment", "Users", "an Entire Generation" ])
end

def WindowsUpdate()
  "Latest Windows " +
  any([ "Patch", "Update", "Service Pack" ]) + " " +
  any([ "Causes More Problems Than It Solves", "Destroys Network", "Contains Virus", "Is a Mess", "Less Than Optimal" ])
end

def MicrosoftRandom() "Microsoft " + EvilVerb() + " " + Victims() end
def FileSharing() EvilOrg() + " " + EvilVerb() + " " + Victims() end

def Google()
  foo = rand(4)
  if foo == 0:
    x = MundaneApp()
    "New Google G" + x.sub(" ","") + " Beta Doesn't Just Reinvent the " + x
  elsif foo == 1:
    "Google's Long-Awaited Web-based " + MundaneApp() + " Enters Beta"
  elsif foo == 2:
    "Google's Next Recruits; World's Elite " + RandomProfession() + "s"
  else
    "Google Does It Again"
  end
end

def WebsiteOutage() Website() + " Experiences " + ShortTime() + " Outage, Users " + BadNoun() end

def MozillaDitchFeature() "Mozilla To Ditch Firefox's " + GoodBrowserFeature() + " Support For Experimental " + StupidFuturisticFirefoxFeature() end

def NerdOSSuffix()
  foo = rand(4)
  if foo == 0:
    "Now Supports " + ArcaneFeature()
  elsif foo == 1:
    any([ "Voted Best", "Smash Hit", "Cracked" ]) + " At " + NerdCon()
  elsif foo == 2
    "Forked"
  else
    "Released"
  end
end

def Space() [ SpaceAgency(), SpaceVessel(), SpaceVerb(), SpaceBullshit() ].join(" "); end

def Physics()
  foo = rand(1+1-0)
  if foo == 0
    any([ "Elusive", "Virtual", "Quantum", "Puzzling", "\"Impossible\"" ]) + " " +
    PhysicsBullshit() +
    " Particle " +
    any([ "Discovered", "Never Existed", "Theorized", "Modeled", "Observed", "Detected" ])
  else
    ParticleAccelerator()
  end
end

def ParticleAccelerator()
  foo = rand(3)
  if foo == 0
    LastName() + " Particle Accelerator Data Will Take " + LongTime() + " to Process"
  elsif foo == 1
    "Particle Accelerator " + any([ "Repairs", "Upgrade", "Construction", "Tune Up", "Systems Test", "Reboot" ]) + " Will " + any([ "Take " + LongTime(), "Cost $" + BigNumber() ])
  else
    LastName() + " Particle Accelerator Bug Means " + LongTime()[0..-2] + " Delay"
  end
end

def Math()
  [
    any([ "New", "Existing", "Surprising", "Optimized", "Powerful", "Exponential" ]),
    any([ "Pattern", "Algorithm", "Power Series", "Financial Model", "Sequence", "Non-Euclidean Geometery" ]),
    any([ "Discovered in", "Found in", "Explains", "Simplifies", "Derived From", "Sheds Light on", "Changes Our Understanding of", "Has Huge Ramifications for" ]),
    any([ "Prime Numbers", "Stock Market", "Financial Markets", "Evolution", "the Cosmos", "Spacetime", "String Theory", "Fluid Dynamics", "Soap Bubbles", "Knots", "Turbulence" ])
  ].join(" ")
end

def NerdOS()
  foo = rand(3)
  if foo == 0
    "Linux"
  elsif foo == 1
    RandomBSD()
  else
    RandomOS()
  end
end

def BigNumber() (rand(990)+10).to_s + " " + any([ "Million", "Billion", "Trillion" ]); end

def ProgrammingLanguageOrFramework() any([ lambda{ ProgrammingLanguage() }, lambda{ Framework() } ]).call; end
def ShortTime() (rand(59)+1).to_s + " " + ShortTimeUnit() end
def LongTime() (rand(6)+5).to_s + " " + LongTimeUnit() end
def RandomBSD() Prefix() + "BSD"; end
def RandomOS() Prefix() + "OS"; end

def GameVersion() (1+rand(9)).to_s; end

def SimpleVersion() rand(10).to_s; end

def OSVersion(os)
  if "Linux" == os:
    LinuxVersion()
  else
    Version()
  end
end

def Version()
  ver = SimpleVersion() + "." + SimpleVersion()
  if rand(2) == 0
    ver = ver + "." + SimpleVersion()
  end
  ver
end

def ArcaneFeature() TechnoAdjective() + " " + TechnoNoun() + " " + TechnoVerb() end
def NerdCon() Prefix() + "Con"; end
def StupidSoftwareName() Consonant().to_s.upcase() + " " + Vowel() + " " + Vowel() + " " + Consonant() + " " + Vowel() end

def any(l); l[rand(l.length)]; end

def WindowsPrefix()
  any([
    "Critical Vulnerability Discovered in",
    "Microsoft Discontinues Support for",
    "Hackers Poke Holes in",
    "Linux Performance Trumps",
    "What Can't You Do In Linux You Can Do In"
  ])
end

def Prefix() any([ "Free", "Net", "Open", "Source", "Nerd", "StarTrek", "React", "Hacker", "Wifi", "Shmoo", "Foo" ]); end
def NerdTopic() any([ "Text Editor", "Regular Expression", "Database Query", "Functional Programming Language", "Hacking Technique", "Stack-Smasher", "Cmdline", "Keyboard Shortcut", "Spam Solution", "Algorithm", "x86 Opcode", "DRM Workaround", "Filesharing Strategy", "Micro-Optimization", "Design Pattern" ]); end
def VenerableProduct () any([ "Google", "Oracle", "Relational Database", "Windows", "Wifi", "TCP", "HTTP", "Search Engine", "Desktop", "Server" ]); end
def TechnoAdjective() any([ "Recursive", "Front-end", "Back-end", "Object-Oriented", "Extreme", "Efficient", "Optimized", "Obfuscated", "Flash-based", "Cached", "Content-based", "Effective", "P=NP", "P!=NP", "Linear", "Functional", "O(1)", "O(log n)", "O(n)", "O(n^2)" ]); end
def TechnoNoun() any([ "Filesystem", "Kernel", "Module", "Dependency", "Touchscreen", "Pen Input", "USB", "Serial Port", "SCSI", "Storage", "TCP", "CPU", "Network" ]); end
def TechnoVerb() any([ "Unloading", "Loading", "Injection", "Healing", "Filtering", "Balancing" ]); end
def WindowsVersion() any([ "3.11", "95", "98", "ME", "XP", "Server 2003", "Vista", "7" ]); end
def ProgrammingLanguage() any([ "PHP", "Perl", "Python", "Ruby", "Lisp", "Lua" ]); end
def Framework() any([ "Drupal", "PHPMyAdmin", "Rails", "Django", "Twisted", "Google Gears", "MySQL" ]); end
def Website() any([ "CNN.com", "Facebook", "Digg", "Youtube", "MSNBC.com", "Yahoo.com", "Google.com", "GMail", "Twitter" ]); end
def TechCompany() any([ "Oracle", "Microsoft", "Sun", "Hewlett Packard", "Dell", "Yahoo!", "IBM" ]); end
def BadNoun() any([ "Angry", "Confused", "Oblivious", "Scared" ]); end
def ShortTimeUnit() any([ "Second", "Minute", "Hour" ]); end
def LongTimeUnit() any([ "Days", "Weeks", "Months", "Years", "Decades" ]); end
def EvilOrg() any([ "MPAA", "RIAA", "ISP" ]); end
def EvilVerb() any([ "Sues", "Hates", "Blocks", "Rootkits", "Monitors", "Cancels" ]); end
def Victims() any([ "Customers", "Contractors", "Users", "Visitors", "Children", "Computerless Grandmother" ]); end
def MundaneApp() any([ "Email", "Word Processor", "Text Editor", "Spreadsheet", "BIOS", "Database" ]); end
def SpaceAgency() any([ "NASA", "European Space Agency", "China" ]); end
def SpaceVessel() any([ "Shuttle", "Probe", "Satellite", "Rocket", "RamJet" ]); end
def SpaceVerb() any([ "Launches", "Deploys", "Repairs", "Loses", "Headed For", "Docks With", "Links Up To" ]); end
def SpaceBullshit() any([ "Important Bolt", "Heatshield", "Experiment", "Sensor", "Orbit", "Mars" ]); end
def Vowel() any("aeiou".split(//)); end
def Consonant() any("bcdfghjklmnpqrtvwxyz".split(//)); end
def GoodBrowserFeature() any([ "URLs", "Links", "Text", "Image", "Icons", "Mouse Pointer", "Tabs", "Extensions", "Multithreading", "HTTP/1.1", "Mouse Gestures", "Audio Support", "Scrolling" ]); end
def StupidFuturisticFirefoxFeature() any([ "Awesome Bar", "3D Hologram", "Klingon Language Support", "Invisible Icons", "Upside-Down Pages", "Single Pixel", "Neural Interface", "Joystick" ]); end
def PhysicsBullshit() any([ "Quasi", "Zig-Zag", "Upside-Down", "Triple-Flavored", "Inside-Out" ]); end
def Rate() "/" + any([ "sec", "min", "hr" ]); end
def Amount() any([ "kbit", "Mbit", "GBit", "Tbit", "Pbit", "Ybit" ]); end
def TechnoRate() (100+rand(900)).to_s + " " + Amount() + Rate() end
def RandomProfession() any([ "Janitor", "Gardener", "Architect", "Rollerskater", "Superintendent", "Chef", "Bicyclist", "Juggler", "Comedian" ]); end

def TechOrganization() StupidSoftwareName() + any(["Soft", "!", "Studios", " Corp"]); end
def Profession() any([ "CEO", "President", "Founder", "Chairman", "Project Lead", "Guru", "Architect", "Designer", "Creator", "Programmer" ]); end
def RandomName() FirstName() + " " + LastName() end
def FirstName() any([ "Arthur", "Bob", "Carl", "David", "Earl", "Fred", "George", "Harold", "Ivan", "Julia", "Kevin", "Larry", "Margaret", "Michael", "Nancy", "Rory", "Ted", "Tracy" ]); end
def LastName() any([ "Anderson", "Blevins", "Carmack", "Daniels", "Johnson", "Kelvin", "Morris", "Neilson", "Savage", "Smith" ]); end

def Patentable() MundaneComputerVerb() + " " + MundaneComputerNoun() end
def MundaneComputerVerb() any([ "Coloring", "Resizing", "Sorting", "Linking", "Printing", "Retrieving", "Storing" ]); end
def MundaneComputerNoun() any([ "Harddrives", "Text", "Images", "Messages", "Email" ]); end

def GovOrg() any([ "CIA", "NSA", "NRO", "FBI", "Military", "DARPA", "Management" ]); end
def PersonalThing() any([ "Phone Calls", "Emails", "Handwriting", "HAM Radio Broadcasts", "Dreams", "Nocturnal Emissions" ]); end
def DeadWords() any([ "Dead", "Obsolete", "Finished", "Worth It", "Valuable", "On the Way Out", "Stupid", "Done For" ]); end

end

