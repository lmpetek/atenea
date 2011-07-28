require "rubygems"
require "google_spreadsheet"
class SpreadsheetController < ApplicationController 
  before_filter :authenticate, :except => [:login, :verify]
  
  def cargar 
    # Logs in.
    # You can also use OAuth. See document of GoogleSpreadsheet.login_with_oauth for details.
    
    session = self.login
    
    #self.verify
    #session = GoogleSpreadsheet.login(@username,@password)
  
    ss = session.create_spreadsheet("Pacient calendar")
    @ws = ss.add_worksheet('hoja1')
    
    # First worksheet of http://spreadsheets.google.com/ccc?key=pz7XtlQC-PYx-jrVMJErTcg&hl=en
    #ws = session.spreadsheet_by_key("pz7XtlQC-PYx-jrVMJErTcg").worksheets[0]
  
    # Gets content of A2 cell.
    p @ws[2, 1] #==> "hoge"
  
    # Changes content of cells. Changes are not sent to the server until you call ws.save().
    @ws[2, 1] = "foo"
    @ws[2, 2] = "bar"
    @ws.save()
  
    # Dumps all cells.
    for row in 1..ws.num_rows
      for col in 1..ws.num_cols
        p @ws[row, col]
      end
    end
  
    # Yet another way to do so.
    p @ws.rows #==> [["fuga", ""], ["foo", "bar]]
  
    # Reloads the worksheet to get changes by other clients.
    @ws.reload()
  end
  
  def login
     GoogleSpreadsheet.login("lmpetek@gmail.com", "Nicolas92")
  end
  
end