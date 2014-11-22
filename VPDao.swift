  func getVPStructureForDelegate(delegate: VPDAODelegateProtocol, toLocale: String, fromLocale: String, context: NSManagedObjectContext) -> Void{
      var url: String = ""
      //.. more url values
      //...

      var success: ((NSData?, (()->Void)!) -> (Void))? = {
          (data: NSData?, cleanup: (()->Void)!) -> Void in

          var error: NSError? = nil
          var d: AnyObject? = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers, error: &error) as NSDictionary

          if(error != nil){
              self.doJsonError(data, error: error)
              return
          }
          else{
              if d != nil {
                  var gospel: AnyObject? = d!.objectForKey("gospelPrinciples")
                  var missionary: AnyObject? = d!.objectForKey("missionaryTasks")
                  var other: AnyObject? = d!.objectForKey("otherVocabulary")
                  //Parsing Data in Child Context
                  context.performBlock{
                      Categories.processCategoryInTasksArray(gospel! as NSArray,name: "Gospel Principles", forContext: context)
                      Categories.processCategoryInTasksArray(missionary! as NSArray,name: "Missionary Tasks", forContext: context)
                      Categories.processCategoryInTasksArray(other! as NSArray,name: "Other Vocabulary", forContext: context)
                      context.save(nil)
                      println("Save Completed")
                      delegate.gotVPStructure()
                  }
              }
          }
          if cleanup != nil{
              cleanup()
          }
          return
      }

      let path = NSBundle.mainBundle().pathForResource("tempStuff", ofType: "json")
      let tempJSON = NSData(contentsOfFile: path!, options: nil, error: nil)
      success!(tempJSON, nil)
  }
