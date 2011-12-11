xquery version "1.0";

module namespace ddi = "http://dda.dk/ddi";

import module namespace result = "http://dda.dk/ddi/result" at "file:///C:/Users/kp/Dropbox/DDA/DDA-IPF/result-functions.xquery";(:"xmldb:exist:///db/dda/result-functions.xquery":)
(:import module namespace kwic="http://exist-db.org/xquery/kwic";:)

declare namespace i="ddi:instance:3_1";
declare namespace su="ddi:studyunit:3_1";
declare namespace r="ddi:reusable:3_1";
declare namespace dc="ddi:datacollection:3_1";
declare namespace cc="ddi:conceptualcomponent:3_1";
declare namespace lp="ddi:logicalproduct:3_1";

declare namespace sp="http://dda.dk/ddi/search-parameters";
declare namespace ss="http://dda.dk/ddi/search-scope";


(:~
 : Makes a free-text search in StudyUnit elements and returns the element(s) containing the match
 :
 : @author  Kemal Pajevic
 : @version 1.0
 : @param   $search-string the string that needs to be matched
 :)
declare function local:queryStudyUnit($search-string as xs:string) as element()* {
    collection('/db/dda')//su:StudyUnit/@id[ft:query(., $search-string)] |
    collection('/db/dda')//r:Creator[ft:query(., $search-string)] |
    collection('/db/dda')//r:Title[ft:query(., $search-string)] |
    collection('/db/dda')//r:Keyword[ft:query(., $search-string)] |
    collection('/db/dda')//r:LevelName[ft:query(., $search-string)] |
    collection('/db/dda')//r:Content[ft:query(., $search-string)] |
    collection('/db/dda')//r:Content[ft:query(., $search-string)] |
    collection('/db/dda')//su:KindOfData[ft:query(., $search-string)]
};

(:~
 : Makes a free-text search in Concept elements and returns the element(s) containing the match
 :
 : @author  Kemal Pajevic
 : @version 1.0
 : @param   $search-string the string that needs to be matched
 :)
declare function local:queryConcept($search-string as xs:string) as element()* {
    collection('/db/dda')//cc:Concept[ft:query(r:Label, $search-string)] |
    collection('/db/dda')//cc:Concept[ft:query(r:Description, $search-string)]
};

(:~
 : Makes a free-text search in Universe elements and returns the element(s) containing the match
 :
 : @author  Kemal Pajevic
 : @version 1.0
 : @param   $search-string the string that needs to be matched
 :)
declare function local:queryUniverse($search-string as xs:string) as element()* {
    collection('/db/dda')//cc:Universe[ft:query(r:Label, $search-string)] |
    collection('/db/dda')//cc:Universe[ft:query(cc:HumanReadable, $search-string)]
};

(:~
 : Makes a free-text search in QuestionItem elements and returns the element(s) containing the match
 :
 : @author  Kemal Pajevic
 : @version 1.0
 : @param   $search-string the string that needs to be matched
 :)
declare function local:queryQuestion($search-string as xs:string) as element()* {
    collection('/db/dda')//dc:QuestionItem[ft:query(dc:QuestionItemName, $search-string)] |
    collection('/db/dda')//dc:QuestionItem[ft:query(dc:QuestionText/dc:LiteralText/dc:Text, $search-string)] |
    collection('/db/dda')//dc:MultipleQuestionItem[ft:query(dc:MultipleQuestionItemName, $search-string)] |
    collection('/db/dda')//dc:MultipleQuestionItem[ft:query(dc:QuestionText/dc:LiteralText/dc:Text, $search-string)]
};

(:~
 : Makes a free-text search in Variable elements and returns the element(s) containing the match
 :
 : @author  Kemal Pajevic
 : @version 1.0
 : @param   $search-string the string that needs to be matched
 :)
declare function local:queryVariable($search-string as xs:string) as element()* {
    collection('/db/dda')//lp:Variable[ft:query(lp:VariableName, $search-string)] |
    collection('/db/dda')//lp:Variable[ft:query(r:Label, $search-string)]
};

(:~
 : Makes a free-text search in Category elements and returns the element(s) containing the match
 :
 : @author  Kemal Pajevic
 : @version 1.0
 : @param   $search-string the string that needs to be matched
 :)
declare function local:queryCategory($search-string as xs:string) as element()* {
    collection('/db/dda')//lp:Category[ft:query(r:Label, $search-string)]
};

(:~
 : Makes a LightXmlObjectList element containing the info based on the result list
 :
 : @author  Kemal Pajevic
 : @version 1.0
 : @param   $results the result list to process
 : @param   $hits-perpage  the number of hits to be shown per page
 : @param   $hit-start     number of the first hit to be shown on the page
 :)
declare function local:buildLightXmlObjectList($results as element()*, $hits-perpage as xs:integer, $hit-start as xs:integer) as element() {
    let $result-count := count($results)
    let $hit-end := if ($result-count lt $hits-perpage) then $result-count
                    else $hit-start + $hits-perpage
    let $number-of-pages :=  xs:integer(ceiling($result-count div $hits-perpage))
    let $current-page := xs:integer(($hit-start + $hits-perpage) div $hits-perpage)

    return <dl:LightXmlObjectList xmlns:dl="ddieditor-lightobject"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="ddieditor-lightobject ddieditor-lightxmlobject.xsd"
        xmlns:smd="http://dda.dk/ddi/search-metadata">
        <smd:SearchMetaData
            result-count="{$result-count}"
            hit-start="{$hit-start}"
            hit-end="{$hit-end}"
            hits-perpage="{$hits-perpage}"
            number-of-pages="{$number-of-pages}"
            current-page="{$current-page}"/>
        {
        for $result in $results[position() = $hit-start to $hit-end]
        order by ft:score($result) descending
            return result:buildResultListItem($result)
        (:kwic:summarize($result, <config width="40"/>):)
        }
    </dl:LightXmlObjectList>
};

(:~
 : Searches for a QuestionItem and returns a LightXmlObjectList element with the result
 :
 : @author  Kemal Pajevic
 : @version 1.0
 : @param   $questionId    the ID of the QuestionItem
 :)
declare function ddi:lookupQuestion($questionId as xs:string) as element() {
    let $question := collection('/db/dda')//dc:QuestionItem[ft:query(@id, $questionId)]
    return <dl:LightXmlObjectList xmlns:dl="ddieditor-lightobject"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="ddieditor-lightobject ddieditor-lightxmlobject.xsd"
        xmlns:smd="http://dda.dk/ddi/search-metadata">
            {result:buildResultListItem($question)}
    </dl:LightXmlObjectList>
};

(:~
 : Searches for a Variable and returns a LightXmlObjectList element with the result
 :
 : @author  Kemal Pajevic
 : @version 1.0
 : @param   $variableId    the ID of the Variable
 :)
declare function ddi:lookupVariable($variableId as xs:string) as element() {
    let $variable := collection('/db/dda')//lp:Variable[ft:query(@id, $variableId)]
    return <dl:LightXmlObjectList xmlns:dl="ddieditor-lightobject"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="ddieditor-lightobject ddieditor-lightxmlobject.xsd"
        xmlns:smd="http://dda.dk/ddi/search-metadata">
            {result:buildResultListItem($variable)}
    </dl:LightXmlObjectList>
};

(:~
 : Searches for a Concept and returns a LightXmlObjectList element with the result
 :
 : @author  Kemal Pajevic
 : @version 1.0
 : @param   $conceptId    the ID of the Concept
 :)
declare function ddi:lookupConcept($conceptId as xs:string) as element() {
    let $concept := collection('/db/dda')//cc:Concept[ft:query(@id, $conceptId)]
    return <dl:LightXmlObjectList xmlns:dl="ddieditor-lightobject"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="ddieditor-lightobject ddieditor-lightxmlobject.xsd"
        xmlns:smd="http://dda.dk/ddi/search-metadata">
            {result:buildResultListItem($concept)}
    </dl:LightXmlObjectList>
};

(:~
 : Searches for a Universe and returns a LightXmlObjectList element with the result
 :
 : @author  Kemal Pajevic
 : @version 1.0
 : @param   $universeId    the ID of the Universe
 :)
declare function ddi:lookupUniverse($universeId as xs:string) as element() {
    let $universe := collection('/db/dda')//cc:Universe[ft:query(@id, $universeId)]
    return <dl:LightXmlObjectList xmlns:dl="ddieditor-lightobject"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="ddieditor-lightobject ddieditor-lightxmlobject.xsd"
        xmlns:smd="http://dda.dk/ddi/search-metadata">
            {result:buildResultListItem($universe)}
    </dl:LightXmlObjectList>
};

(:~
 : Searches for a Category and returns a LightXmlObjectList element with the result
 :
 : @author  Kemal Pajevic
 : @version 1.0
 : @param   $categoryId    the ID of the Category
 :)
declare function ddi:lookupCategory($categoryId as xs:string) as element() {
    let $category := collection('/db/dda')//lp:Category[ft:query(@id, $categoryId)]
    return <dl:LightXmlObjectList xmlns:dl="ddieditor-lightobject"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="ddieditor-lightobject ddieditor-lightxmlobject.xsd"
        xmlns:smd="http://dda.dk/ddi/search-metadata">
            {result:buildResultListItem($category)}
    </dl:LightXmlObjectList>
};

(:~
 : Makes a free-text search in all indexed elements and returns a list of LightXmlObject elements with the results
 :
 : @author  Kemal Pajevic
 : @version 1.0
 : @param   $search-string the string that needs to be matched
 : @param   $hits-perpage  number of hits to be shown per page
 : @param   $hit-start     number of the first hit to be shown on the page
 : @param   $scope         the search scope wrapped in a SearchScope element
 :)
declare function ddi:simpleSearch($search-string as xs:string, $hits-perpage as xs:integer, $hit-start as xs:integer, $scope as element()) as element() {
    let $studyUnitScope := if ($scope/ss:StudyUnit) then local:queryStudyUnit($search-string) else ()
    let $conceptScope := if ($scope/ss:Concept) then local:queryConcept($search-string) else ()
    let $universeScope := if ($scope/ss:Universe) then local:queryUniverse($search-string) else ()
    let $questionScope := if ($scope/ss:Question) then local:queryQuestion($search-string) else ()
    let $variableScope := if ($scope/ss:Variable) then local:queryVariable($search-string) else ()
    let $categoryScope := if ($scope/ss:Category) then local:queryCategory($search-string) else ()
    
    let $results := 
        $studyUnitScope |
        $conceptScope   |
        $universeScope  |
        $questionScope  |
        $variableScope  |
        $categoryScope
    return local:buildLightXmlObjectList($results, $hits-perpage, $hit-start)
};

(:~
 : Makes a free-text search in all indexed elements and returns a list of LightXmlObject elements with the results
 :
 : @author  Kemal Pajevic
 : @version 1.0
 : @param   $searchParameters  the search parameters wrapped in a SearchParameters element
 : @param   $hits-perpage      number of hits to be shown per page
 : @param   $hit-start         number of the first hit to be shown on the page
 :)
declare function ddi:advancedSearch($searchParameters as element(), $hits-perpage as xs:integer, $hit-start as xs:integer) as element() {
    let $searchScope := if ($searchParameters/sp:studyId) then <W>{data($searchParameters/sp:studyId)}</W>
    else <w/>
    return $searchScope
(:    let $studyUnitResults :=
        collection('/db/dda')//su:StudyUnit/@id[ft:query(., $studyId)]                            &
        collection('/db/dda')//r:Citation/r:Title[ft:query(., $title)]               &
        collection('/db/dda')//su:Abstract/r:Content[ft:query(., $abstract-purpose)] &
        collection('/db/dda')//su:Purpose/r:Content[ft:query(., $abstract-purpose)]  &
        collection('/db/dda')//r:Citation/r:Creator[ft:query(., $creator)]           &
        collection('/db/dda')//su:StudyUnit/su:KindOfData[ft:query(., $search-string)]:)
    (:let $results :=
        local:queryConcept($concept)   |
        local:queryUniverse($universe)  |
        local:queryQuestion($question)  |
        local:queryVariable($variable)  |
        local:queryCategory($category)
    return local:buildLightXmlObjectList($results, $hits-perpage, $hit-start):)
};

let $scope :=
    <SearchScope xmlns="http://dda.dk/ddi/search-scope" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <StudyUnit/>
        <Concept/>
        <Universe/>
        <Question/>
        <Variable/>
        <Category/>
    </SearchScope>

return ddi:simpleSearch('National', 10, 0, $scope)(:'14069':)
(:let $searchParameters :=
    <SearchParameters xmlns="http://dda.dk/ddi/search-parameters" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <studyId>studyId0</studyId>
        <title>title0</title>
        <abstract-purpose>abstract-purpose0</abstract-purpose>
        <creator>creator0</creator>
        <kindOfData>kindOfData0</kindOfData>
        <coverageFrom>2006-05-04</coverageFrom>
        <coverageTo>2006-05-04</coverageTo>
        <concept>concept0</concept>
        <universe>universe0</universe>
        <question>question0</question>
        <variable>variable0</variable>
        <category>category0</category>
    </SearchParameters>
return ddi:advancedSearch($searchParameters, 10, 0):)
(:ddi:lookupQuestion('quei-40b54010-32c6-4b7c-9f1e-6b8f662462c1'):)
(:ddi:lookupVariable('vari-1-9db0a9d8-2fd3-425f-aaf2-67ddd0b677ef'):)
(:ddi:lookupConcept('conc-695fdb22-4bf1-4359-9647-4a1c421593d1'):)
(:ddi:lookupUniverse('eafc0dde-0b5e-4449-b3dd-09071f6a2707'):)
(:ddi:lookupCategory('cat-d4ebcb36-9409-4b41-bdaa-ece686b5f772'):)