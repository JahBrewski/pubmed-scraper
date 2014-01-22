require 'fileutils'
require 'rubygems'
require 'pubmed_search'
require 'mechanize'
require 'bio'

@search_query = "\"therapeutic misconception\"[All Fields] AND English[lang]"
@email = "joelbrewer01@gmail.com"
@downloaded = 0
@not_downloaded = 0


class URLException < Exception
end

def run
  Bio::NCBI.default_email = "joelbrewer01@gmail.com"
  pmids = get_pmids(@search_query)
  download_pdfs_given_pmids(pmids)
end

def get_pmids(query)
  PubmedSearch::search(query).pmids
end

def download_pdfs_given_pmids(pmids)
  pmids.each do |pmid|
    download_pdf_given_pmid(pmid)
  end
  File.open("downloaded.txt", 'a') { |f| f.write("\nTotal Downloaded: #{@downloaded}") }
  File.open("not-downloaded.txt", 'a') { |f| f.write("\nTotal Not Downloaded: #{@not_downloaded}") }
end

def download_pdf_given_pmid(pmid)
  a = Mechanize.new
  a.get("http://www.ncbi.nlm.nih.gov/pubmed/#{pmid}/") do |page|
    title = get_paper_title_given_pmid(pmid)
    
    if download_pdf_from_page(page, a, pmid) != nil
      File.open("downloaded.txt", 'a') { |f| f.write("\n#{pmid} - #{title}") }
      @downloaded = @downloaded + 1
    else
      File.open("not-downloaded.txt", 'a') { |f| f.write("\n#{pmid} - #{title}") }
      @not_downloaded = @not_downloaded + 1
    end
  end
end

def download_pdf_from_page(page, a, pmid)

  article_page = page.link_with(:text => 'Free PMC Article') || nil

  if article_page
    article_page = page.link_with(:text => 'Free PMC Article').click
  else return nil
  end

  #search for pdf link
  pdf_link = article_page.link_with(:href => /.*pdf.*/) || nil

  if pdf_link
    begin
      a.get(pdf_link.uri.to_s).save_as("#{get_paper_title_given_pmid(pmid)}.pdf")
    rescue 
      return nil
    end
  else return nil
  end
end

def get_paper_title_given_pmid(pmid)
  article = Bio::PubMed.efetch(pmid)
  article[0].to_s.match(/[T][I]\s*[-]\s*(.*)$/)[1].gsub(' ','_')
  
end

run
