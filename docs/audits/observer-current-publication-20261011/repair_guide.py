"""Repair first guide label substitution without rewriting admitted evidence."""
from pathlib import Path
from common import BASE, canonical, need, pin, save
import book


def main():
    current=book.CHAPTER.read_bytes();before,first=book.source()
    need(current==first[str(book.CHAPTER)],'whole actual first guide and unchanged source peers')
    (BASE/'first-book-source.md.txt').write_bytes(current)
    (BASE/'first-book-registry.jsonl.txt').write_bytes(book.REGISTRY.read_bytes())
    desired=(BASE/'guide.txt').read_text()
    need(book.ADDITION==desired.replace('original-header','observer-current'),'exact root cause is broad label replacement within reviewed prose')
    producer=(BASE/'book.py').read_text()
    start=producer.index('ADDITION = ');end=producer.index('\n\ndef git',start)
    producer=producer[:start]+'ADDITION = '+repr(desired)+producer[end:]
    producer=producer.replace('need(current==before,', 'need(current==__import__(\'book\').source()[1],',1)
    producer=producer.replace("save('book-publication.json'", "save('book-publication-qualified.json'",1)
    (BASE/'book_qualified.py').write_text(producer)
    reader=(BASE/'publication_verify.py').read_text().replace('import book\n','import book_qualified as book\n',1)
    reader=reader.replace("load('book-publication.json')","load('book-publication-qualified.json')")
    reader=reader.replace("'publication-proof.json'","'publication-proof-qualified.json'")
    (BASE/'publication_verify_qualified.py').write_text(reader)
    save('guide-repair.json',dict(cause='A global original-header to observer-current programme-label replacement unintentionally rewrote three complete reviewed guide phrases.',
         first_programme=pin((BASE/'book.py').read_bytes()),qualified_programme=pin(producer.encode()),
         whole_first_guide=book.ADDITION,whole_qualified_guide=desired,first_chapter=pin(current),
         first_actual='checks.json/focused-python',admitted_preparation='Retained unchanged; first book programme is dated candidate evidence, not the qualified publisher.',
         resolution='Exact guide bytes feed the qualified producer; full expected current/native guide and original source contracts must pass without weakening assertions.'))
    print('PASS complete first guide/programme/refusal retained and exact correction prepared; final publication verification remains pending.')


if __name__=='__main__':main()
