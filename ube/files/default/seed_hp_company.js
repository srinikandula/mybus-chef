var hp = {
  "_class": "com.shodogg.ube.model.core.Company",
  "addresses": [],
  "adminUserIds": [],
  "attrs": {
  },
  "childCompanyIds": [],
  "configurationSettings": {
    "ADMINS_CAN_CREATE_ADMINS": "true",
    "ADMINS_CAN_CREATE_CHILD_COMPANY_ADMINS": "true",
    "ADMINS_CAN_CREATE_CHILD_COMPANY_USERS": "true",
    "ADMINS_CAN_DELETE_CHILD_COMPANY": "true",
    "ADMINS_CAN_DELETE_OWN_COMPANY": "false",
    "CAN_BE_VIEWED_BY_CHILDREN_ADMINS": "false",
    "CHILD_COMPANIES_CAN_ACCESS_RESOURCES": "true",
    "PARENT_COMPANY_CAN_ACCESS_RESOURCES": "false"
  },
  "createdAt": new Date(),
  "deleted": false,
  "groupIds": [],
  "name": "HP",
  "updatedAt": new Date()
}
db.company.insert(hp);

var comport = {
  "_class": "com.shodogg.ube.model.core.Company",
  "name": "Comport",
  "addresses": [

  ],
  "adminUserIds": [
  ],
  "groupIds": [
  ],
  "childCompanyIds": [

  ],
  "configurationSettings": {
    "ADMINS_CAN_CREATE_ADMINS": "true",
    "ADMINS_CAN_CREATE_CHILD_COMPANY_ADMINS": "true",
    "ADMINS_CAN_CREATE_CHILD_COMPANY_USERS": "true",
    "ADMINS_CAN_DELETE_CHILD_COMPANY": "true",
    "ADMINS_CAN_DELETE_OWN_COMPANY": "false",
    "CAN_BE_VIEWED_BY_CHILDREN_ADMINS": "false",
    "CHILD_COMPANIES_CAN_ACCESS_RESOURCES": "true",
    "PARENT_COMPANY_CAN_ACCESS_RESOURCES": "false"
  },
  "deleted": false,
  "createdAt": new Date(),
  "updatedAt": new Date(),
  "attrs": {

  }
}
db.company.insert(comport);

var comportId = db.company.find({"name": "Comport"}).next()._id.valueOf();
db.company.update({"name":"HP"}, {$push : {"childCompanyIds" : comportId}});

