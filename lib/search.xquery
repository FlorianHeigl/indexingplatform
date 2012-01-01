xquery version "1.0";

module namespace ddi = "http://dda.dk/ddi";

import module namespace result = "http://dda.dk/ddi/result" at "file:///C:/Users/kp/Dropbox/DDA/DDA-IPF/lib/result-functions.xquery";(:"xmldb:exist:///db/dda/lib/result-functions.xquery":)
(:import module namespace kwic="http://exist-db.org/xquery/kwic";:)

declare namespace i="ddi:instance:3_1";
declare namespace su="ddi:studyunit:3_1";
declare namespace r="ddi:reusable:3_1";
declare namespace dc="ddi:datacollection:3_1";
declare namespace cc="ddi:conceptualcomponent:3_1";
declare namespace lp="ddi:logicalproduct:3_1";

declare namespace ssp="http://dda.dk/ddi/simple-search-parameters";
declare namespace asp="http://dda.dk/ddi/advanced-search-parameters";
declare namespace smd="http://dda.dk/ddi/search-metadata";
declare namespace s="http://dda.dk/ddi/scope";


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
declare function local:queryQuestionItem($search-string as xs:string) as element()* {
    collection('/db/dda')//dc:QuestionItem[ft:query(dc:QuestionItemName, $search-string)] |
    collection('/db/dda')//dc:QuestionItem[ft:query(dc:QuestionText/dc:LiteralText/dc:Text, $search-string)]
};

(:~
 : Makes a free-text search in MultipleQuestionItem elements and returns the element(s) containing the match
 :
 : @author  Kemal Pajevic
 : @version 1.0
 : @param   $search-string the string that needs to be matched
 :)
declare function local:queryMultipleQuestionItem($search-string as xs:string) as element()* {
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
        xmlns:rmd="http://dda.dk/ddi/result-metadata">
        <rmd:ResultMetaData
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
 : @param   $questionItemId    the ID of the QuestionItem
 :)
declare function ddi:lookupQuestionItem($questionItemId as xs:string) as element() {
    let $questionItem := collection('/db/dda')//dc:QuestionItem[ft:query(@id, $questionItemId)]
    return <dl:LightXmlObjectList xmlns:dl="ddieditor-lightobject"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="ddieditor-lightobject ddieditor-lightxmlobject.xsd"
        xmlns:smd="http://dda.dk/ddi/search-metadata">
            {result:buildResultListItem($questionItem)}
    </dl:LightXmlObjectList>
};

(:~
 : Searches for a MultipleQuestionItem and returns a LightXmlObjectList element with the result
 :
 : @author  Kemal Pajevic
 : @version 1.0
 : @param   $multipleQuestionItemId    the ID of the QuestionItem
 :)
declare function ddi:lookupMultipleQuestionItem($multipleQuestionItemId as xs:string) as element() {
    let $multipleQuestionItem := collection('/db/dda')//dc:MultipleQuestionItem[ft:query(@id, $multipleQuestionItemId)]
    return <dl:LightXmlObjectList xmlns:dl="ddieditor-lightobject"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="ddieditor-lightobject ddieditor-lightxmlobject.xsd"
        xmlns:smd="http://dda.dk/ddi/search-metadata">
            {result:buildResultListItem($multipleQuestionItem)}
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
 : @param   $search-parameters the search parameters wrapped in a SimpleSearchParameters element with the following format:<br/>
 :          &lt;ssp:SimpleSearchParameters xmlns:smd="http://dda.dk/ddi/search-metadata"<br/>
 :           &#160;&#160;xmlns:ssp="http://dda.dk/ddi/simple-search-parameters"<br/>
 :           &#160;&#160;xmlns:s="http://dda.dk/ddi/scope"<br/>
 :           &#160;&#160;xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"&gt;<br/>
 :              &#160;&#160;&#160;&#160;&lt;ssp:search-string&gt;some text&lt;/ssp:search-string&gt;  &lt;!-- The text we are searching for (xs:string). Required. --&gt;<br/>
 :              &#160;&#160;&#160;&#160;&lt;smd:SearchMetaData hits-perpage="10" hit-start="0"/&gt;   &lt;!-- The number of hits we wish to show per page (xs:positiveInteger) and the number of the first result we wish to get (xs:nonNegativeInteger). Both required. --&gt;<br/>
 :              &#160;&#160;&#160;&#160;&lt;s:Scope&gt;                                               &lt;!-- The scope of our search. Each child-element is optional and if it is present the search will return results of the type specified by that element (if found). The child-elements have no type or content; only the existence is checked. --&gt;<br/>
 :                  &#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&lt;s:StudyUnit/&gt;<br/>
 :                  &#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&lt;s:Variable/&gt;<br/>
 :                  &#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&lt;s:QuestionItem/&gt;<br/>
 :                  &#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&lt;s:MultipleQuestionItem/&gt;<br/>
 :                  &#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&lt;s:Universe/&gt;<br/>
 :                  &#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&lt;s:Concept/&gt;<br/>
 :                  &#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&lt;s:Category/&gt;<br/>
 :              &#160;&#160;&#160;&#160;&lt;/s:Scope&gt;<br/>
 :          &lt;/ssp:SimpleSearchParameters&gt;<br/>
 :)
declare function ddi:simpleSearch($search-parameters as element()) as element() {
    let $search-string := data($search-parameters/ssp:search-string)
    let $search-metadata := $search-parameters/smd:SearchMetaData
    let $search-scope := $search-parameters/s:Scope

    let $studyUnitScope := if ($search-scope/s:StudyUnit) then local:queryStudyUnit($search-string) else ()
    let $variableScope := if ($search-scope/s:Variable) then local:queryVariable($search-string) else ()
    let $questionItemScope := if ($search-scope/s:QuestionItem) then local:queryQuestionItem($search-string) else ()
    let $multipleQuestionItemScope := if ($search-scope/s:MultipleQuestionItem) then local:queryMultipleQuestionItem($search-string) else ()
    let $universeScope := if ($search-scope/s:Universe) then local:queryUniverse($search-string) else ()
    let $conceptScope := if ($search-scope/s:Concept) then local:queryConcept($search-string) else ()
    let $categoryScope := if ($search-scope/s:Category) then local:queryCategory($search-string) else ()
    
    let $results := 
        $studyUnitScope            |
        $variableScope             |
        $questionItemScope         |
        $multipleQuestionItemScope |
        $universeScope             |
        $conceptScope              |
        $categoryScope

    return local:buildLightXmlObjectList($results, data($search-metadata/@hits-perpage), data($search-metadata/@hit-start))
};

(:~
 : Makes a free-text search in all indexed elements and returns a list of LightXmlObject elements with the results
 :
 : @author  Kemal Pajevic
 : @version 1.0
 : @param   $search-parameters the search parameters wrapped in a AdvancedSearchParameters element with the following format:<br/>
 :          &lt;asp:AdvancedSearchParameters xmlns:smd="http://dda.dk/ddi/search-metadata"
 :           &#160;&#160;xmlns:asp="http://dda.dk/ddi/advanced-search-parameters"
 :           &#160;&#160;xmlns:s="http://dda.dk/ddi/scope"
 :           &#160;&#160;xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"&gt;
 :              &#160;&#160;&#160;&#160;&lt;asp:studyId&gt;studyId0&lt;/asp:studyId&gt;                                              &lt;!-- Id of the StudyUnit we wish to limit the results to (xs:string). Optional. --&gt;<br/>
 :              &#160;&#160;&#160;&#160;&lt;asp:title&gt;title0&lt;/asp:title&gt;                                                    &lt;!-- Title of the StudyUnit(s) we wish to limit the results to (xs:string). Optional. --&gt;<br/>
 :              &#160;&#160;&#160;&#160;&lt;asp:topicalCoverage&gt;topicalCoverage0&lt;/asp:topicalCoverage&gt;                      &lt;!-- TopicalCoverage of the StudyUnit(s) we wish to limit the results to (xs:string). Optional. --&gt;<br/>
 :              &#160;&#160;&#160;&#160;&lt;asp:spatialCoverage&gt;spatialCoverage0&lt;/asp:spatialCoverage&gt;                      &lt;!-- SpatialCoverage of the StudyUnit(s) we wish to limit the results to (xs:string). Optional. --&gt;<br/>
 :              &#160;&#160;&#160;&#160;&lt;asp:abstract-purpose&gt;abstract-purpose0&lt;/asp:abstract-purpose&gt;                   &lt;!-- Purpose of the StudyUnit(s) we wish to limit the results to (xs:string). Optional. --&gt;<br/>
 :              &#160;&#160;&#160;&#160;&lt;asp:creator&gt;creator0&lt;/asp:creator&gt;                                              &lt;!-- Creator of the StudyUnit(s) we wish to limit the results to (xs:string). Optional. --&gt;<br/>
 :              &#160;&#160;&#160;&#160;&lt;asp:kindOfData&gt;kindOfData0&lt;/asp:kindOfData&gt;                                     &lt;!-- KindOfData of the StudyUnit(s) we wish to limit the results to (xs:string). Optional. --&gt;<br/>
 :              &#160;&#160;&#160;&#160;&lt;asp:coverageFrom&gt;2006-05-04&lt;/asp:coverageFrom&gt;                                  &lt;!-- Starting coverage date of the StudyUnit we wish to limit the results to (xs:date). Optional. --&gt;<br/>
 :              &#160;&#160;&#160;&#160;&lt;asp:coverageTo&gt;2006-05-04&lt;/asp:coverageTo&gt;                                      &lt;!-- Ending coverage date of the StudyUnit we wish to limit the results to (xs:date). Optional. --&gt;<br/>
 :              &#160;&#160;&#160;&#160;&lt;asp:Variable&gt;variable text&lt;/asp:Variable&gt;                                       &lt;!-- Search-text for the Variable(s) we wish to find (xs:string). If left out Variable will not be searched and returned. Optional. --&gt;<br/>
 :              &#160;&#160;&#160;&#160;&lt;asp:QuestionItem&gt;questionItem text&lt;/asp:QuestionItem&gt;                           &lt;!-- Search-text for the QuestionItem(s) we wish to find (xs:string). If left out QuestionItem will not be searched and returned. Optional. --&gt;<br/>
 :              &#160;&#160;&#160;&#160;&lt;asp:MultipleQuestionItem&gt;multipleQuestionItem text&lt;/asp:MultipleQuestionItem&gt;   &lt;!-- Search-text for the MultipleQuestionItem(s) we wish to find (xs:string). If left out MultipleQuestionItem will not be searched and returned. Optional. --&gt;<br/>
 :              &#160;&#160;&#160;&#160;&lt;asp:Universe&gt;universe text&lt;/asp:Universe&gt;                                       &lt;!-- Search-text for the Universe(s) we wish to find (xs:string). If left out Universe will not be searched and returned. Optional. --&gt;<br/>
 :              &#160;&#160;&#160;&#160;&lt;asp:Concept&gt;concept text&lt;/asp:Concept&gt;                                          &lt;!-- Search-text for the Coverage(s) we wish to find (xs:string). If left out Coverage will not be searched and returned. Optional. --&gt;<br/>
 :              &#160;&#160;&#160;&#160;&lt;asp:Category&gt;category text&lt;/asp:Category&gt;                                       &lt;!-- Search-text for the Category(s) we wish to find (xs:string). If left out Category will not be searched and returned. Optional. --&gt;<br/>
 :              &#160;&#160;&#160;&#160;&lt;smd:SearchMetaData hits-perpage="2" hit-start="1"/&gt;                                   &lt;!-- The number of hits we wish to show per page (xs:positiveInteger) and the number of the first result we wish to get (xs:nonNegativeInteger). Both required. --&gt;<br/>
 :              &#160;&#160;&#160;&#160;&lt;s:Scope&gt;                                                                              &lt;!-- The scope of our results. Each child-element is optional and if it is present the search will for all found results return a list of references of the type specified by that element (if any exist). The child-elements have no type or content; only the existence is checked. --&gt;<br/>
 :                  &#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&lt;s:StudyUnit/&gt;<br/>
 :                  &#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&lt;s:Variable/&gt;<br/>
 :                  &#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&lt;s:QuestionItem/&gt;<br/>
 :                  &#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&lt;s:MultipleQuestionItem/&gt;<br/>
 :                  &#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&lt;s:Universe/&gt;<br/>
 :                  &#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&lt;s:Concept/&gt;<br/>
 :                  &#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&lt;s:Category/&gt;<br/>
 :              &#160;&#160;&#160;&#160;&lt;/s:Scope&gt;<br/>
 :          &lt;/asp:AdvancedSearchParameters&gt;<br/>
 :)
declare function ddi:advancedSearch($search-parameters as element()) as element()* {
    let $studyFromId :=
        if($search-parameters/asp:studyId) then
            let $studyId := string($search-parameters/asp:studyId)
            return collection('/db/dda')//su:StudyUnit[ft:query(@id, $studyId)] else ()
    let $studyFromTitle :=
        if($search-parameters/asp:title) then
            let $studyTitle := string($search-parameters/asp:title)
            return collection('/db/dda')//su:StudyUnit[ft:query(r:Citation/r:Title, $studyTitle)] else ()
    let $studyFromTopicalCoverage :=
        if($search-parameters/asp:topicalCoverage) then
            let $studyTopicalCoverage := string($search-parameters/asp:topicalCoverage)
            return collection('/db/dda')//su:StudyUnit[ft:query(r:Coverage/r:TopicalCoverage/r:Keyword, $studyTopicalCoverage)] else ()
    let $studyFromSpatialCoverage :=
        if($search-parameters/asp:spatialCoverage) then
            let $studySpatialCoverage := string($search-parameters/asp:spatialCoverage)
            return collection('/db/dda')//su:StudyUnit[ft:query(r:Coverage/r:SpatialCoverage/r:TopLevelReference/r:LevelName, $studySpatialCoverage)] else ()
    let $studyFromAbstractPurpose :=
        if($search-parameters/asp:abstract-purpose) then
            let $studyAbstractPurpose := string($search-parameters/asp:abstract-purpose)
            return collection('/db/dda')//su:StudyUnit[ft:query(su:Abstract/r:Content, $studyAbstractPurpose)] | 
                   collection('/db/dda')//su:StudyUnit[ft:query(su:Purpose/r:Content, $studyAbstractPurpose)] else ()
    let $studyFromCreator :=
        if($search-parameters/asp:creator) then
            let $studyCreator := string($search-parameters/asp:creator)
            return collection('/db/dda')//su:StudyUnit[ft:query(r:Citation/r:Creator, $studyCreator)] else ()
    let $studyFromKindOfData :=
        if($search-parameters/asp:kindOfData) then
            let $studyKindOfData := string($search-parameters/asp:kindOfData)
            return collection('/db/dda')//su:StudyUnit[ft:query(su:KindOfData, $studyKindOfData)] else ()
    let $studyFromTemporalCoverage :=
        if($search-parameters/asp:coverageFrom) then
            let $studyFrom := dateTime($search-parameters/asp:coverageFrom, xs:time('00:00:00.000+01:00'))
            return if($search-parameters/asp:coverageTo) then
                let $studyTo := dateTime($search-parameters/asp:coverageTo, xs:time('00:00:00.000+01:00'))
                return collection('/db/dda')//su:StudyUnit[r:Coverage/r:TemporalCoverage/r:ReferenceDate/r:StartDate ge $studyFrom and r:Coverage/r:TemporalCoverage/r:ReferenceDate/r:EndDate le $studyTo] 
            else
                collection('/db/dda')//su:StudyUnit[r:Coverage/r:TemporalCoverage/r:ReferenceDate/r:StartDate ge $studyFrom]
        else
            if($search-parameters/asp:coverageTo) then
                let $studyTo := dateTime($search-parameters/asp:coverageTo, xs:time('00:00:00.000+01:00'))
                return collection('/db/dda')//su:StudyUnit[r:Coverage/r:TemporalCoverage/r:ReferenceDate/r:EndDate le $studyTo]
            else ()
    
    let $variableSearch := if ($search-scope/s:Variable) then local:queryVariable($search-string) else ()
    let $questionItemSearch := if ($search-scope/s:QuestionItem) then local:queryQuestionItem($search-string) else ()
    let $multipleQuestionItemSearch := if ($search-scope/s:MultipleQuestionItem) then local:queryMultipleQuestionItem($search-string) else ()
    let $universeSearch := if ($search-scope/s:Universe) then local:queryUniverse($search-string) else ()
    let $conceptSearch := if ($search-scope/s:Concept) then local:queryConcept($search-string) else ()
    let $categorySearch := if ($search-scope/s:Category) then local:queryCategory($search-string) else ()
   
    (:for $studyUnit in $studyFromTemporalCoverage
        return <w>{$studyUnit/@id}</w>:)

    (:let $results :=
        local:queryConcept($concept)   |
        local:queryUniverse($universe)  |
        local:queryQuestion($question)  |
        local:queryVariable($variable)  |
        local:queryCategory($category)
    return local:buildLightXmlObjectList($results, $hits-perpage, $hit-start):)
};