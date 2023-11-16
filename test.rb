require "google_drive"

class RadnaPovrsina
  include Enumerable
  attr_accessor :worksheet
  attr_accessor :total_red

  def initialize(kljuc,list);
    session = GoogleDrive::Session.from_config("config.json")
    spreadsheet = session.spreadsheet_by_key(kljuc)
    @worksheet = spreadsheet.worksheets[list]
    @total_red = uzmi_total()
    makeMethods()
  end
  
  def uzmi_total()
    total = -1
    vrati_niz.each.each_with_index do |red,index|
      red.each do |polje|
        if polje == "total" || polje == "subtotal"
          total = index
        end
      end
    end
    total
  end

  def vrati_niz()
   @worksheet.rows
  end

  def vrati_red(num)
    if num != @total_red
     @worksheet.rows[num]
    end
  end

  def each
    vrati_niz.each do |red|
      red.each { |item| yield item }
    end
  end

  def makeMethods()
   
    hdr = 0
    vrati_red(hdr).each_with_index do |header,index|
      RadnaPovrsina.class_eval do
        define_method(header.split(/ /).map{ |w| w[0] = w[0].downcase; w }.join) do
          self[header]
        end
      end

    end

  end

 

  def vrati_index(vrednost)
    hdr = 0
    br_kolone = -1
    
    vrati_red(hdr).each_with_index do |header,index|
      if header == vrednost
        br_kolone = index
        break
      end
    end
    br_kolone
  end

  def [](vrednost)
    
    br_kolone = vrati_index(vrednost)
    if br_kolone == -1
      p "Ne psotoji header sa tim nazivom"
      return
    else
      PristupKolonama.new(self,br_kolone + 1)
    end
    
  end

  def -(drugaT)
    brojac = 0
    if drugaT.is_a?(RadnaPovrsina)
      vrati_niz.each_with_index do |red,index|
        brojac+=1
        flag = red.all? { |element| element == "" } 
        next if index.zero?
        next if flag
       drugaT.vrati_niz.each do |red2|
          if red == red2
           self.worksheet.delete_rows(brojac, 1)
           brojac -= 1
          end
       end
       
      end
    self.worksheet.save
    else
      raise ArgumentError, "Greska ne mogu se oduzimati #{drugaT.class} objekti"
    end
  end

  def +(drugaT)
    list = []
    n = 0
    br = 1
    if drugaT.is_a?(RadnaPovrsina)
      vrati_niz.each_with_index do |red,index|
        
        flag = red.all? { |element| element == "" }  
        br += 1
        
        next if index.zero?
        next if flag
        n += 1
        br -=1 
        list << red
      end
       drugaT.vrati_niz.each_with_index do |red2,index2|
        flag = red2.all? { |element| element == "" }  
        next if index2.zero?
        next if flag
        p index2
        p @total_red
        next if index2 == drugaT.total_red
            list << red2 unless list.include?(red2)        
       end
      list.shift(n)
      
     
      self.worksheet.insert_rows(br, list)
     
 
      #self.worksheet.save
    else
      raise ArgumentError, "Greska ne mogu se oduzimati #{drugaT.class} objekti"
    end
  end

  class PristupKolonama
    def initialize(radnaPovrsina,kolona)
      @radnaPovrsina = radnaPovrsina
      @kolona = kolona
      makeMethods()
    end
    def makeMethods()
   
      @radnaPovrsina.vrati_niz.each_with_index do |red,index|
        str = red[@kolona - 1].downcase
        PristupKolonama.class_eval do
          define_method(str) do
            @radnaPovrsina.vrati_red(index)
          end
        end
      end 
    end


    def[](red)
      @radnaPovrsina.worksheet[red,@kolona]
    end

   
    def []=(red, nova_vrednost)
      @radnaPovrsina.worksheet[red,@kolona] = nova_vrednost
      @radnaPovrsina.worksheet.save
    end

    def sum
      sum = 0
      @radnaPovrsina.vrati_niz.each_with_index do |red,index|
        next if index.zero?
        if index != @radnaPovrsina.total_red
          value = red[@kolona - 1].to_i
          sum += value
        end
      end
      p "Sum: #{sum}"
    end

    def avg
      sum = 0.0
      br = 0
      @radnaPovrsina.vrati_niz.each_with_index do |red,index|
        next if index.zero?
        if index != @radnaPovrsina.total_red
          value = red[@kolona - 1].to_i
          sum += value
          br += 1
          p value
        end
      end
      p "Average: #{sum/br}"
    end
  end
  
end

kljuc = "10WPzWhq1uy5WfZ3XQRVOS_RHn6XdvSO-Wo8jYwLLbjA"
list1 = 0
list2 = 1
t1 = RadnaPovrsina.new(kljuc,list1)
t2 = RadnaPovrsina.new(kljuc,list2)


# Vrati dvo niz
# t1.vrati_niz

# vrati redove
#t1.vrati_red(2)

# Ispisis sve elemente
#t1.each { |celija| p celija }
# Direktan pristup kolonama
# p t1["Prva Kolona"]

#pristup vrednostima
# t1["Prva Kolona"][3]

#Promena vrednosti
# t1["Prva Kolona"][3]= 400

# Pristup kolonama preko metoda
# t1.prvakolona

#Sum i avg
# t1.prvakolona.sum
# t2.drugakolona.avg

# izvlacenje reda preko jedne celije
#t1.index.rn22
#mora se dopisati u tabelu indexi

#Prepoznaje total
# t1.vrati_red(8)

#sabiranje
# p t2.vrati_niz
# p t1.vrati_niz
# t2 + t1
# p"------------------"
# p t2.vrati_niz

#oduzimanje
# p t2.vrati_niz
# p t1.vrati_niz
# t2 + t1
# p"------------------"
# p t2.vrati_niz

