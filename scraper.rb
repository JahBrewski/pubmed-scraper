require 'fileutils'
require 'rubygems'
require 'pubmed_search'
require 'mechanize'
require 'bio'

@search_query = "\"therapeutic misconception\"[All Fields] AND English[lang]"
@email = "joelbrewer01@gmail.com"

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
end

def download_pdf_given_pmid(pmid)
  a = Mechanize.new
  a.get("http://www.ncbi.nlm.nih.gov/pubmed/#{pmid}/") do |page|
    download_pdf_from_page(page, a, pmid)
  end
end

def download_pdf_from_page(page, a, pmid)
  article_page = page.link_with(:text => 'Free PMC Article') || nil
    if article_page
      article_page = page.link_with(:text => 'Free PMC Article').click
      #search for pdf link
      pdf_link = article_page.link_with(:href => /.*pdf.*/) || nil

      if pdf_link
        # save pdf
        begin
          a.get(pdf_link.uri.to_s).save_as("#{get_paper_title_given_pmid(pmid)}.pdf")
        rescue 
          return
        end
      end
    end
end

def get_paper_title_given_pmid(pmid)
  article = Bio::PubMed.efetch(pmid)
  article[0].to_s.match(/[T][I]\s*[-]\s*(.*)$/)[1].gsub(' ','_')
  
end

run
