require "google_drive"

def convert(input_string)
  no_spaces = input_string.gsub(/\s+/, '')

  lowercase_string = no_spaces.downcase

  camel_case_string = lowercase_string.split.map.with_index do |word, index|
    index == 0 ? word : word.capitalize
  end.join

  camel_case_string
end

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

      str = convert(header)
      RadnaPovrsina.class_eval do
        define_method(str) do
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
    brojac = 2
    if drugaT.is_a?(RadnaPovrsina)
      vrati_niz.each_with_index do |red,index|
        flag = red.all? { |element| element == "" }  
        next if index.zero?
        next if flag
       drugaT.vrati_niz.each do |red2|
          if red == red2
           self.worksheet.delete_rows(brojac, 1)
           brojac -= 1
          end
       end
       brojac+=1
      end
    self.worksheet.save
    else
      raise ArgumentError, "Greska ne mogu se oduzimati #{drugaT.class} objekti"
    end
  end

  def +(drugaT)
    list = []
    n = 0
    if drugaT.is_a?(RadnaPovrsina)
      vrati_niz.each_with_index do |red,index|
        flag = red.all? { |element| element == "" }  
        next if index.zero?
        next if flag 
        list << red
        n += 1
      end
       drugaT.vrati_niz.each_with_index do |red2,index2|
        flag = red2.all? { |element| element == "" }  
        next if index2.zero?
        next if flag
            list << red2 unless list.include?(red2)        
       end
      list.shift(n)
      
     
      self.worksheet.insert_rows(3, list)
     
 
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
        if red[@kolona - 1] != ""
          value = red[@kolona - 1].to_i
          sum += value
          p value
        end
      end
      p "Sum: #{sum}"
    end

    def avg
      sum = 0.0
      br = 0
      @radnaPovrsina.vrati_niz.each_with_index do |red,index|
        next if index.zero?
        if red[@kolona - 1] != ""
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


#t1.each { |celija| p celija }
# p t1["Prva Kolona"][3] 
# t1["Prva Kolona"][3]= 400
#t1["Prva Kolona"]
# p t1.vrati_niz
# p "-------------------------"
# p t2.vrati_niz
p t1.vrati_niz
p t2.vrati_niz
t1 + t2
p"------------------"
p t1.vrati_niz

# p t1.vrati_red(7)
# t2-t1