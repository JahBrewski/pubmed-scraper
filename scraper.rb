require 'fileutils'
require 'rubygems'
require 'bio'
require 'pubmed_search'
require 'mechanize'

@search_query = "\"therapeutic misconception\"[All Fields] AND English[lang]"
@email = "joelbrewer01@gmail.com"


def run
  pmids = get_pmids(@search_query).each do |pmid|
    a = Mechanize.new

    article_page = return_article_page_given_pmid(pmid, a)

    free_article_page = check_for_free_article(article_page) || nil

    if free_article_page
      pdf_link = free_article_page.link_with(:href => /.*pdf.*/) || nil
      if pdf_link
        a.get(pdf_link.uri.to_s).save_as "#{pdf_link.to_s}"
        File.open("downloaded.txt", 'a') { |f| f.write("#{pmid} -- #{pdf_link.to_s}") }
      end
    else
      File.open("not_downloaded.txt", 'a') { |f| f.write("#{pmid}") }
    end
  end
end

def get_pmids(query)
  PubmedSearch::search(query).pmids
end

def return_article_page_given_pmid(pmid, a)
  a.get("http://www.ncbi.nlm.nih.gov/pubmed/#{pmid}/")
end

def check_for_free_article(page)
  if page.link_with(:text => 'Free PMC Article')
    return page.link_with(:text => 'Free PMC Article').click
  else
    return false
  end
end

run
